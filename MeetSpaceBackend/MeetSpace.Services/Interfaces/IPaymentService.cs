using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Interfaces
{
    public interface IPaymentService
    {
        Task<PaymentIntentResponse> CreatePaymentIntentAsync(
            CreatePaymentIntentRequest request,
            int currentUserId,
            CancellationToken ct = default);

        Task<ConfirmPaymentResponse> ConfirmPaymentAsync(
            ConfirmPaymentRequest request,
            int currentUserId,
            CancellationToken ct = default);
    }
}