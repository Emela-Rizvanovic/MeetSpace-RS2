using Azure.Storage.Blobs;
using MeetSpace.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using MeetSpace.Models.Exceptions;

public class BlobService : IBlobService
{
    private readonly BlobServiceClient _blobServiceClient;
    private readonly string _userImagesContainer;
    private readonly string _spaceImagesContainer;
    private static readonly HashSet<string> AllowedContentTypes = new(StringComparer.OrdinalIgnoreCase)
{
    "image/jpeg",
    "image/png",
    "image/webp"
};

    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
{
    ".jpg",
    ".jpeg",
    ".png",
    ".webp"
};

    public BlobService(IConfiguration config)
    {
        _blobServiceClient = new BlobServiceClient(
       Environment.GetEnvironmentVariable("AZURE_BLOB_CONNECTION")
   );

        _userImagesContainer =
            Environment.GetEnvironmentVariable("AZURE_USER_CONTAINER")!;

        _spaceImagesContainer =
            Environment.GetEnvironmentVariable("AZURE_SPACE_CONTAINER")!;
    }

    public async Task<string> UploadUserImageAsync(IFormFile file)
    {
        return await UploadFileAsync(file, _userImagesContainer);
    }

    public async Task<bool> DeleteUserImageAsync(string url)
    {
        return await DeleteFileAsync(url, _userImagesContainer);
    }

    public async Task<string> UploadSpaceImageAsync(IFormFile file)
    {
        return await UploadFileAsync(file, _spaceImagesContainer);
    }

    public async Task<bool> DeleteSpaceImageAsync(string url)
    {
        return await DeleteFileAsync(url, _spaceImagesContainer);
    }

    private async Task<string> UploadFileAsync(IFormFile file, string containerName)
    {
        await ValidateImageFileAsync(file);

        var container = _blobServiceClient.GetBlobContainerClient(containerName);
        await container.CreateIfNotExistsAsync();

        string extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        string fileName = $"{Guid.NewGuid()}{extension}";
        var blobClient = container.GetBlobClient(fileName);

        using var stream = file.OpenReadStream();
        await blobClient.UploadAsync(stream, overwrite: true);

        return blobClient.Uri.ToString();
    }

    private static async Task ValidateImageFileAsync(IFormFile file)
    {
        if (file == null || file.Length == 0)
            throw new BusinessException("File is required and cannot be empty.");

        if (file.Length > 5 * 1024 * 1024)
            throw new BusinessException("File size must be up to 5 MB.");

        var extension = Path.GetExtension(file.FileName);

        if (string.IsNullOrWhiteSpace(extension) || !AllowedExtensions.Contains(extension))
            throw new BusinessException("File extension must be .jpg, .jpeg, .png, or .webp.");

        if (string.IsNullOrWhiteSpace(file.ContentType) || !AllowedContentTypes.Contains(file.ContentType))
            throw new BusinessException("File MIME type must be image/jpeg, image/png, or image/webp.");

        await using var stream = file.OpenReadStream();

        var header = new byte[12];
        var bytesRead = await stream.ReadAsync(header, 0, header.Length);

        if (!HasValidImageSignature(header, bytesRead, file.ContentType))
            throw new BusinessException("File content must match a valid JPEG, PNG, or WEBP image.");
    }

    private static bool HasValidImageSignature(byte[] header, int bytesRead, string contentType)
    {
        if (contentType.Equals("image/jpeg", StringComparison.OrdinalIgnoreCase))
        {
            return bytesRead >= 3 &&
                   header[0] == 0xFF &&
                   header[1] == 0xD8 &&
                   header[2] == 0xFF;
        }

        if (contentType.Equals("image/png", StringComparison.OrdinalIgnoreCase))
        {
            return bytesRead >= 8 &&
                   header[0] == 0x89 &&
                   header[1] == 0x50 &&
                   header[2] == 0x4E &&
                   header[3] == 0x47 &&
                   header[4] == 0x0D &&
                   header[5] == 0x0A &&
                   header[6] == 0x1A &&
                   header[7] == 0x0A;
        }

        if (contentType.Equals("image/webp", StringComparison.OrdinalIgnoreCase))
        {
            return bytesRead >= 12 &&
                   header[0] == 0x52 &&
                   header[1] == 0x49 &&
                   header[2] == 0x46 &&
                   header[3] == 0x46 &&
                   header[8] == 0x57 &&
                   header[9] == 0x45 &&
                   header[10] == 0x42 &&
                   header[11] == 0x50;
        }

        return false;
    }

    public async Task<bool> DeleteFileAsync(string fileUrl, string containerName)
    {
        var container = _blobServiceClient.GetBlobContainerClient(containerName);

        string fileName = Path.GetFileName(fileUrl);
        var blobClient = container.GetBlobClient(fileName);

        return await blobClient.DeleteIfExistsAsync();
    }
}
