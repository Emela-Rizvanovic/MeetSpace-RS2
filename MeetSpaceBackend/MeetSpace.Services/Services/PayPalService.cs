using MeetSpace.Models.Entities;
using MeetSpace.Models.Enums;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Net.Http.Headers;
using System.Text;

namespace MeetSpace.Services.Services
{
    public class PayPalService : IPayPalService
    {
        private readonly MeetSpaceDbContext _context;
        private readonly IBookingService _bookingService;

        public PayPalService(
            MeetSpaceDbContext context,
            IBookingService bookingService)
        {
            _context = context;
            _bookingService = bookingService;
        }

        public async Task<PayPalOrderResponse> CreateOrderAsync(
            decimal amount,
            CancellationToken ct = default)
        {
            var client = new HttpClient();

            var auth = Convert.ToBase64String(Encoding.UTF8.GetBytes(
                $"{Environment.GetEnvironmentVariable("PAYPAL_CLIENT_ID")}:{Environment.GetEnvironmentVariable("PAYPAL_SECRET")}"
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
            dynamic tokenData = JsonConvert.DeserializeObject(tokenJson);
            string accessToken = tokenData.access_token;

            client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", accessToken);

            var eurAmount = amount / 1.95583m;

            var orderBody = new
            {
                intent = "CAPTURE",
                purchase_units = new[]
                {
                    new
                    {
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

            return new PayPalOrderResponse
            {
                Url = approvalUrl,
                OrderId = orderId
            };
        }

        public async Task<PayPalCaptureResponse> CaptureAsync(
            PayPalCaptureRequest request,
            int currentUserId,
            CancellationToken ct = default)
        {
            var client = new HttpClient();

            var auth = Convert.ToBase64String(Encoding.UTF8.GetBytes(
                $"{Environment.GetEnvironmentVariable("PAYPAL_CLIENT_ID")}:{Environment.GetEnvironmentVariable("PAYPAL_SECRET")}"
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
            dynamic tokenData = JsonConvert.DeserializeObject(tokenJson);
            string accessToken = tokenData.access_token;

            client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", accessToken);

            var captureResponse = await client.PostAsync(
                $"https://api-m.sandbox.paypal.com/v2/checkout/orders/{request.OrderId}/capture",
                new StringContent("", Encoding.UTF8, "application/json"),
                ct);

            var captureJson = await captureResponse.Content.ReadAsStringAsync(ct);
            dynamic captureData = JsonConvert.DeserializeObject(captureJson);

            var captureStatus = captureData["purchase_units"]?[0]?["payments"]?["captures"]?[0]?["status"]?.ToString();

            if (captureStatus != "COMPLETED")
                throw new ApplicationException("Payment not completed");

            await using var transaction = await _context.Database.BeginTransactionAsync(ct);

            var bookingRequest = new BookingInsertRequest
            {
                SpaceId = request.SpaceId,
                UserId = currentUserId,
                StartTime = request.StartTime,
                EndTime = request.EndTime,
                Amenities = request.Amenities
                    .Select(x => new BookingAmenityInsertRequest
                    {
                        AmenityId = x.AmenityId,
                        Quantity = x.Quantity
                    })
                    .ToList()
            };

            var bookingResponse =
                await _bookingService.CreateAsync(bookingRequest, ct);

            await _context.SaveChangesAsync(ct);

            var payment = new Payment
            {
                BookingId = bookingResponse.Id,
                UserId = currentUserId,
                PaymentMethodId = (int)PaymentMethodEnum.PayPal,
                PaymentStatusId = (int)PaymentStatusEnum.Completed,
                Amount = bookingResponse.TotalPrice,
                PaymentDate = DateTime.UtcNow
            };

            _context.Payments.Add(payment);

            await _context.SaveChangesAsync(ct);

            await transaction.CommitAsync(ct);

            return new PayPalCaptureResponse
            {
                BookingId = bookingResponse.Id
            };
        }
    }
}