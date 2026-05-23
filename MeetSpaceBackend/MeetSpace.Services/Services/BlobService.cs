using Azure.Storage.Blobs;
using MeetSpace.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using System.Globalization;

public class BlobService : IBlobService
{
    private readonly BlobServiceClient _blobServiceClient;
    private readonly string _userImagesContainer;
    private readonly string _spaceImagesContainer;

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

    // User Images
    public async Task<string> UploadUserImageAsync(IFormFile file)
    {
        return await UploadFileAsync(file, _userImagesContainer);
    }

    public async Task<bool> DeleteUserImageAsync(string url)
    {
        return await DeleteFileAsync(url, _userImagesContainer);
    }

    // Space Images
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
        var container = _blobServiceClient.GetBlobContainerClient(containerName);
        await container.CreateIfNotExistsAsync();

        string fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
        var blobClient = container.GetBlobClient(fileName);

        using var stream = file.OpenReadStream();
        await blobClient.UploadAsync(stream, overwrite: true);

        return blobClient.Uri.ToString();
    }

    public async Task<bool> DeleteFileAsync(string fileUrl, string containerName)
    {
        var container = _blobServiceClient.GetBlobContainerClient(containerName);

        string fileName = Path.GetFileName(fileUrl);
        var blobClient = container.GetBlobClient(fileName);

        return await blobClient.DeleteIfExistsAsync();
    }
}
