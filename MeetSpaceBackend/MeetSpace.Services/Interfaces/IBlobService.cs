using Microsoft.AspNetCore.Http;

namespace MeetSpace.Services.Interfaces
{
    public interface IBlobService
    {
        Task<string> UploadUserImageAsync(IFormFile file);
        Task<string> UploadSpaceImageAsync(IFormFile file);

        Task<bool> DeleteUserImageAsync(string fileUrl);
        Task<bool> DeleteSpaceImageAsync(string fileUrl);
    }
}
