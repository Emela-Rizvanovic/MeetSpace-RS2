using MeetSpace.Models.Entities;
using MeetSpace.Models.Enums;
using MeetSpace.Models.Requests;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class PayPalController : ControllerBase
{
    private readonly MeetSpaceDbContext _context;
    private readonly IConfiguration _config;
    private readonly IBookingService _bookingService;
    public PayPalController(
     MeetSpaceDbContext context,
     IConfiguration config,
     IBookingService bookingService)
    {
        _context = context;
        _config = config;
        _bookingService = bookingService;
    }

    [HttpPost("create-order")]
    public async Task<IActionResult> CreateOrder([FromBody] decimal amount)
    {
        var client = new HttpClient();

        // 🔐 uzmi token
        var auth = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(
            $"{_config["PayPal:ClientId"]}:{_config["PayPal:Secret"]}"
        ));

        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Basic", auth);

        var tokenResponse = await client.PostAsync(
            "https://api-m.sandbox.paypal.com/v1/oauth2/token",
            new FormUrlEncodedContent(new[]
            {
                new KeyValuePair<string,string>("grant_type","client_credentials")
            })
        );

        var tokenJson = await tokenResponse.Content.ReadAsStringAsync();
        dynamic tokenData = Newtonsoft.Json.JsonConvert.DeserializeObject(tokenJson);
        string accessToken = tokenData.access_token;

        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);

        var eurAmount = amount / 1.95583m;

        var orderBody = new
        {
            intent = "CAPTURE",
            purchase_units = new[]
            {
        new {
            amount = new {
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
                Newtonsoft.Json.JsonConvert.SerializeObject(orderBody),
                System.Text.Encoding.UTF8,
                "application/json")
        );

        var json = await response.Content.ReadAsStringAsync();
        var data = Newtonsoft.Json.Linq.JObject.Parse(json);

        string approvalUrl = data["links"]
            .First(l => l["rel"].ToString() == "approve")["href"]
            .ToString();

        string orderId = data["id"]?.ToString();

        return Ok(new
        {
            url = approvalUrl,
            orderId = orderId
        });
    }

    [HttpPost("capture")]
    public async Task<IActionResult> Capture([FromBody] PayPalCaptureRequest request)
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
        if (userIdClaim == null)
            return Unauthorized();

        int currentUserId = int.Parse(userIdClaim.Value);

        var client = new HttpClient();

        var auth = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(
            $"{_config["PayPal:ClientId"]}:{_config["PayPal:Secret"]}"
        ));

        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Basic", auth);

        var tokenResponse = await client.PostAsync(
            "https://api-m.sandbox.paypal.com/v1/oauth2/token",
            new FormUrlEncodedContent(new[]
            {
            new KeyValuePair<string,string>("grant_type","client_credentials")
            })
        );

        var tokenJson = await tokenResponse.Content.ReadAsStringAsync();
        dynamic tokenData = Newtonsoft.Json.JsonConvert.DeserializeObject(tokenJson);
        string accessToken = tokenData.access_token;

        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);

        var captureResponse = await client.PostAsync(
            $"https://api-m.sandbox.paypal.com/v2/checkout/orders/{request.OrderId}/capture",
            new StringContent("", System.Text.Encoding.UTF8, "application/json")
        );

        var captureJson = await captureResponse.Content.ReadAsStringAsync();
        dynamic captureData = Newtonsoft.Json.JsonConvert.DeserializeObject(captureJson);

        var captureStatus = captureData["purchase_units"]?[0]?["payments"]?["captures"]?[0]?["status"]?.ToString();

        if (captureStatus != "COMPLETED")
            return BadRequest("Payment not completed");

        Console.WriteLine($"STATUS CODE: {captureResponse.StatusCode}");
        Console.WriteLine(captureJson);

        Console.WriteLine("PAYPAL CAPTURE RESPONSE:");
        Console.WriteLine(captureJson);

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
            await _bookingService.CreateAsync(bookingRequest);

        await _context.SaveChangesAsync();

        var payment = new Payment
        {
            BookingId = bookingResponse.Id,
            UserId = currentUserId,
            PaymentMethodId = (int)PaymentMethodEnum.PayPal, // PayPal
            PaymentStatusId = (int)PaymentStatusEnum.Completed,
            Amount = bookingResponse.TotalPrice,
            PaymentDate = DateTime.UtcNow
        };

        _context.Payments.Add(payment);

        await _context.SaveChangesAsync();

        return Ok(new
        {
            bookingId = bookingResponse.Id
        });
    }
}