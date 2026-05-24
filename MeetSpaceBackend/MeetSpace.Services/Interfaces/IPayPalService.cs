using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Interfaces
{
    public interface IPayPalService
    {
        Task<PayPalOrderResponse> CreateOrderAsync(
            decimal amount,
            CancellationToken ct = default);

        Task<PayPalCaptureResponse> CaptureAsync(
            PayPalCaptureRequest request,
            int currentUserId,
            CancellationToken ct = default);
    }
}