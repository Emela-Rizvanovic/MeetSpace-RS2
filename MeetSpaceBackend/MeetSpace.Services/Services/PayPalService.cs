using MeetSpace.Models.Entities;
using MeetSpace.Models.Enums;
using MeetSpace.Models.Exceptions;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Globalization;
using System.Net.Http.Headers;
using System.Text;

namespace MeetSpace.Services.Services
{
    public class PayPalService : IPayPalService
    {
        private readonly MeetSpaceDbContext _context;
        private readonly IBookingService _bookingService;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly string _payPalClientId;
        private readonly string _payPalSecret;

        public PayPalService(
       MeetSpaceDbContext context,
       IBookingService bookingService,
       IHttpClientFactory httpClientFactory)
        {
            _context = context;
            _bookingService = bookingService;
            _httpClientFactory = httpClientFactory;
            _payPalClientId = Environment.GetEnvironmentVariable("PAYPAL_CLIENT_ID")!;
            _payPalSecret = Environment.GetEnvironmentVariable("PAYPAL_SECRET")!;
        }

        public async Task<PayPalOrderResponse> CreateOrderAsync(
    CreatePayPalOrderRequest request,
    int currentUserId,
    CancellationToken ct = default)
        {
            var client = _httpClientFactory.CreateClient();

            var auth = Convert.ToBase64String(Encoding.UTF8.GetBytes(
     $"{_payPalClientId}:{_payPalSecret}"
 ));

            client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Basic", auth);

            var tokenResponse = await client.PostAsync(
                "https://api-m.sandbox.paypal.com/v1/oauth2/token",
                new FormUrlEncodedContent(new[]
                {
                    new KeyValuePair<string, string>("grant_type", "client_credentials")
                }),
                ct);

            var tokenJson = await tokenResponse.Content.ReadAsStringAsync(ct);
            var tokenData = JObject.Parse(tokenJson);
            string accessToken = tokenData["access_token"]?.ToString();

            client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", accessToken);

            var amount = await _bookingService.ValidateCreatePrerequisitesAndCalculatePriceAsync(
    request.SpaceId,
    request.StartTime,
    request.EndTime,
    request.Amenities,
    ct);

            var eurAmount = amount / 1.95583m;

            var orderBody = new
            {
                intent = "AUTHORIZE",
                purchase_units = new[]
                {
                    new
                    {
                        custom_id = currentUserId.ToString(),
amount = new
{
    currency_code = "EUR",
    value = eurAmount.ToString("F2")
}
                    }
                },
                application_context = new
                {
                    return_url = "meetspace://paypal/success",
                    cancel_url = "meetspace://paypal/cancel"
                }
            };

            var response = await client.PostAsync(
                "https://api-m.sandbox.paypal.com/v2/checkout/orders",
                new StringContent(
                    JsonConvert.SerializeObject(orderBody),
                    Encoding.UTF8,
                    "application/json"),
                ct);

            var json = await response.Content.ReadAsStringAsync(ct);
            var data = JObject.Parse(json);

            string approvalUrl = data["links"]
                .First(l => l["rel"].ToString() == "approve")["href"]
                .ToString();

            string orderId = data["id"]?.ToString();

            if (string.IsNullOrWhiteSpace(orderId))
                throw new BusinessException("PayPal order id was not returned.");

            var paymentDraft = new PaymentIntent
            {
                StripePaymentIntentId = orderId,
                UserId = currentUserId,
                SpaceId = request.SpaceId,
                StartTime = request.StartTime,
                EndTime = request.EndTime,
                AmenitiesSnapshotJson = System.Text.Json.JsonSerializer.Serialize(request.Amenities),
                Amount = amount,
                Currency = "BAM",
                Provider = "PayPal",
                ProviderOrderId = orderId,
                Status = "Created",
                ExpiresAt = DateTime.UtcNow.AddMinutes(30),
                IsCompleted = false
            };

            _context.PaymentIntents.Add(paymentDraft);
            await _context.SaveChangesAsync(ct);

            return new PayPalOrderResponse
            {
                Url = approvalUrl,
                OrderId = orderId,
                Amount = amount
            };
        }

        public async Task<PayPalCaptureResponse> CaptureAsync(
            PayPalCaptureRequest request,
            int currentUserId,
            CancellationToken ct = default)
        {
            var existingPayment = await _context.Payments
    .FirstOrDefaultAsync(x =>
    x.ExternalTransactionId == request.OrderId &&
    x.UserId == currentUserId &&
    x.PaymentMethodId == (int)PaymentMethodEnum.PayPal,
    ct);

            if (existingPayment != null)
            {
                return new PayPalCaptureResponse
                {
                    BookingId = existingPayment.BookingId
                };
            }

            var paymentDraft = await _context.PaymentIntents
    .FirstOrDefaultAsync(x =>
        x.Provider == "PayPal" &&
        x.ProviderOrderId == request.OrderId &&
        x.UserId == currentUserId,
        ct);

            if (paymentDraft == null)
                throw new BusinessException("PayPal order does not belong to the current user.");

            if (paymentDraft.ExpiresAt <= DateTime.UtcNow)
                throw new BusinessException("PayPal order has expired.");

            var amenities = System.Text.Json.JsonSerializer.Deserialize<List<BookingAmenityInsertRequest>>(
    paymentDraft.AmenitiesSnapshotJson
) ?? new();

            var expectedAmount = await _bookingService.ValidateCreatePrerequisitesAndCalculatePriceAsync(
                paymentDraft.SpaceId,
                paymentDraft.StartTime,
                paymentDraft.EndTime,
                amenities,
                ct);

            var client = _httpClientFactory.CreateClient();

            var auth = Convert.ToBase64String(Encoding.UTF8.GetBytes(
     $"{_payPalClientId}:{_payPalSecret}"
 ));

            client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Basic", auth);

            var tokenResponse = await client.PostAsync(
                "https://api-m.sandbox.paypal.com/v1/oauth2/token",
                new FormUrlEncodedContent(new[]
                {
                    new KeyValuePair<string, string>("grant_type", "client_credentials")
                }),
                ct);

            var tokenJson = await tokenResponse.Content.ReadAsStringAsync(ct);
            var tokenData = JObject.Parse(tokenJson);
            string accessToken = tokenData["access_token"]?.ToString();

            client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", accessToken);

            var authorizeResponse = await client.PostAsync(
     $"https://api-m.sandbox.paypal.com/v2/checkout/orders/{request.OrderId}/authorize",
     new StringContent("", Encoding.UTF8, "application/json"),
     ct);

            var authorizeJson = await authorizeResponse.Content.ReadAsStringAsync(ct);
            var authorizeData = JObject.Parse(authorizeJson);

            var customId = authorizeData["purchase_units"]?[0]?["custom_id"]?.ToString();

            if (!string.IsNullOrWhiteSpace(customId) && customId != currentUserId.ToString())
                throw new BusinessException("PayPal order does not belong to the current user.");

            var authorization = authorizeData["purchase_units"]?[0]?["payments"]?["authorizations"]?[0];

            var authorizationStatus = authorization?["status"]?.ToString();

            if (authorizationStatus != "CREATED")
                throw new BusinessException("Payment was not authorized.");

            var authorizationId = authorization?["id"]?.ToString();

            if (string.IsNullOrWhiteSpace(authorizationId))
                throw new BusinessException("PayPal authorization id was not returned.");

            try
            {
                var expectedEurAmount = Math.Round(expectedAmount / 1.95583m, 2);

                var authorizedAmountValue = authorization?["amount"]?["value"]?.ToString();
                var authorizedCurrency = authorization?["amount"]?["currency_code"]?.ToString();

                if (authorizedCurrency != "EUR" ||
                    !decimal.TryParse(authorizedAmountValue, NumberStyles.Number, CultureInfo.InvariantCulture, out var authorizedAmount) ||
                    authorizedAmount != expectedEurAmount)
                {
                    throw new BusinessException("Authorized amount does not match booking price.");
                }

                await using var transaction = await _context.Database.BeginTransactionAsync(ct);

                var bookingRequest = new BookingInsertRequest
                {
                    SpaceId = paymentDraft.SpaceId,
                    UserId = currentUserId,
                    InternalPaymentStatus = PaymentStatusEnum.Authorized,
                    StartTime = paymentDraft.StartTime,
                    EndTime = paymentDraft.EndTime,
                    Amenities = amenities
                };

                var bookingResponse = await _bookingService.CreateAsync(bookingRequest, ct);

                await _context.SaveChangesAsync(ct);

                var payment = new Payment
                {
                    BookingId = bookingResponse.Id,
                    UserId = currentUserId,
                    ExternalTransactionId = request.OrderId,
                    PaymentMethodId = (int)PaymentMethodEnum.PayPal,
                    PaymentStatusId = (int)PaymentStatusEnum.Authorized,
                    Amount = bookingResponse.TotalPrice,
                    PaymentDate = DateTime.UtcNow,
                    ProviderAuthorizationId = authorizationId,
                    PaymentIntentId = paymentDraft.Id,
                };

                _context.Payments.Add(payment);

                paymentDraft.Status = "Authorized";

                await _context.SaveChangesAsync(ct);

                await transaction.CommitAsync(ct);

                return new PayPalCaptureResponse
                {
                    BookingId = bookingResponse.Id
                };
            }
            catch
            {
                await VoidPayPalAuthorizationAsync(authorizationId, ct);

                paymentDraft.Status = "Failed";
                await _context.SaveChangesAsync(ct);

                throw;
            }
        }

        private async Task VoidPayPalAuthorizationAsync(string authorizationId, CancellationToken ct)
        {
            var client = _httpClientFactory.CreateClient();

            var auth = Convert.ToBase64String(Encoding.UTF8.GetBytes(
                $"{_payPalClientId}:{_payPalSecret}"
            ));

            client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Basic", auth);

            var tokenResponse = await client.PostAsync(
                "https://api-m.sandbox.paypal.com/v1/oauth2/token",
                new FormUrlEncodedContent(new[]
                {
            new KeyValuePair<string, string>("grant_type", "client_credentials")
                }),
                ct);

            var tokenJson = await tokenResponse.Content.ReadAsStringAsync(ct);
            var tokenData = JObject.Parse(tokenJson);
            string accessToken = tokenData["access_token"]?.ToString();

            client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", accessToken);

            var voidResponse = await client.PostAsync(
                $"https://api-m.sandbox.paypal.com/v2/payments/authorizations/{authorizationId}/void",
                new StringContent("", Encoding.UTF8, "application/json"),
                ct);

            if (!voidResponse.IsSuccessStatusCode)
                throw new BusinessException("PayPal authorization could not be voided after booking failure.");
        }
    }
}