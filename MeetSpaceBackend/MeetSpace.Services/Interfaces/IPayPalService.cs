using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Interfaces
{
    public interface IPayPalService
    {
        Task<PayPalOrderResponse> CreateOrderAsync(
    CreatePayPalOrderRequest request,
    int currentUserId,
    CancellationToken ct = default);

        Task<PayPalCaptureResponse> CaptureAsync(
            PayPalCaptureRequest request,
            int currentUserId,
            CancellationToken ct = default);
    }
}