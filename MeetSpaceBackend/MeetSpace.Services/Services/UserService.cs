using AutoMapper;
using MeetSpace.Models.Constants;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Messages;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Database.Entities;
using MeetSpace.Services.Interfaces;
using MeetSpace.Services.Security;
using Microsoft.EntityFrameworkCore;
using MeetSpace.Models.Exceptions;
using System.Security.Cryptography;

public class UserService : BaseCRUDService<UserResponse, UserSearchObject, User, UserInsertRequest, UserUpdateRequest>, IUserService
{
    private readonly IPasswordHasher _passwordHasher;
    private readonly IBlobService _blobService;
    private readonly IRabbitMQService _rabbitMQService;
    private const int MaxPasswordResetAttempts = 5;

    public UserService(MeetSpaceDbContext context, IMapper mapper, IPasswordHasher passwordHasher, IBlobService blobService, IRabbitMQService rabbitMQService)
        : base(context, mapper)
    {
        _passwordHasher = passwordHasher;
        _blobService = blobService;
        _rabbitMQService = rabbitMQService;
    }

    protected override IQueryable<User> ApplyFilter(IQueryable<User> query, UserSearchObject search)
    {
        if (!string.IsNullOrWhiteSpace(search.Name))
        {
            query = query.Where(u =>
                u.FirstName.Contains(search.Name) ||
                u.LastName.Contains(search.Name) ||
                u.Username.Contains(search.Name)
            );
        }

        if (!string.IsNullOrWhiteSpace(search.FirstName))
            query = query.Where(u => u.FirstName.Contains(search.FirstName));

        if (!string.IsNullOrWhiteSpace(search.LastName))
            query = query.Where(u => u.LastName.Contains(search.LastName));

        if (!string.IsNullOrWhiteSpace(search.Email))
            query = query.Where(u => u.Email.Contains(search.Email));

        if (search.RoleId.HasValue)
            query = query.Where(u => u.RoleId == search.RoleId.Value);

        if (search.IsActive.HasValue)
            query = query.Where(u => u.IsActive == search.IsActive.Value);

        return query.Include(u => u.Role);
    }

    protected override async Task BeforeInsert(User entity, UserInsertRequest request, CancellationToken cancellationToken = default)
    {
        request.Username = request.Username.Trim();
        request.Email = request.Email.Trim();

        var usernameExists = await _context.Users
            .AnyAsync(u => u.Username == request.Username, cancellationToken);

        if (usernameExists)
            throw new BusinessException("Username already exists.");

        var emailExists = await _context.Users
            .AnyAsync(u => u.Email == request.Email, cancellationToken);

        if (emailExists)
            throw new BusinessException("Email already exists.");

        if (!request.RoleId.HasValue)
            throw new BusinessException("Role is required. Select a valid role.");

        entity.RoleId = request.RoleId.Value;

        entity.PasswordHash = _passwordHasher.Hash(request.Password);
        entity.CreatedAt = DateTime.UtcNow;

        await base.BeforeInsert(entity, request, cancellationToken);
    }

    protected override async Task BeforeUpdate(User entity, UserUpdateRequest request, CancellationToken cancellationToken = default)
    {
        if (!string.IsNullOrWhiteSpace(request.Username))
        {
            request.Username = request.Username.Trim();

            var usernameExists = await _context.Users
                .AnyAsync(u => u.Id != entity.Id && u.Username == request.Username, cancellationToken);

            if (usernameExists)
                throw new BusinessException("Username already exists.");
        }

        if (!string.IsNullOrWhiteSpace(request.Email))
        {
            request.Email = request.Email.Trim();

            var emailExists = await _context.Users
                .AnyAsync(u => u.Id != entity.Id && u.Email == request.Email, cancellationToken);

            if (emailExists)
                throw new BusinessException("Email already exists.");
        }

        entity.UpdatedAt = DateTime.UtcNow;
        await base.BeforeUpdate(entity, request, cancellationToken);
    }
    private async Task<User?> GetUserWithRoleAsync(int id, CancellationToken cancellationToken = default)
    {
        return await _context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);
    }

    public override async Task<UserResponse> CreateAsync(UserInsertRequest request, CancellationToken cancellationToken = default)
    {
        var entity = _mapper.Map<User>(request);

        await BeforeInsert(entity, request, cancellationToken);

        if (request.ProfileImageUrl != null)
        {
            entity.ProfileImageUrl = await _blobService.UploadUserImageAsync(request.ProfileImageUrl);
        }

        _context.Users.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);

        entity = await GetUserWithRoleAsync(entity.Id, cancellationToken);
        return _mapper.Map<UserResponse>(entity);
    }

    public override async Task<UserResponse?> UpdateAsync(int id, UserUpdateRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await GetUserWithRoleAsync(id, cancellationToken);
        if (entity == null)
            return null;

        await BeforeUpdate(entity, request, cancellationToken);

        if (!string.IsNullOrWhiteSpace(request.FirstName))
            entity.FirstName = request.FirstName;

        if (!string.IsNullOrWhiteSpace(request.LastName))
            entity.LastName = request.LastName;

        if (!string.IsNullOrWhiteSpace(request.Email))
            entity.Email = request.Email;

        if (!string.IsNullOrWhiteSpace(request.PhoneNumber))
            entity.PhoneNumber = request.PhoneNumber;

        if (!string.IsNullOrWhiteSpace(request.Username))
            entity.Username = request.Username;

        if (request.RoleId.HasValue)
            entity.RoleId = request.RoleId.Value;

        if (request.IsActive.HasValue)
            entity.IsActive = request.IsActive.Value;

        if (!string.IsNullOrWhiteSpace(request.Password))
        {
            if (!string.IsNullOrWhiteSpace(request.CurrentPassword) &&
                !_passwordHasher.Verify(request.CurrentPassword, entity.PasswordHash))
            {
                throw new BusinessException("Current password is incorrect.");
            }

            entity.PasswordHash = _passwordHasher.Hash(request.Password);
        }

        if (request.ProfileImageUrl != null && request.ProfileImageUrl.Length > 0)
        {
            var newUrl = await _blobService.UploadUserImageAsync(request.ProfileImageUrl);

            if (!string.IsNullOrEmpty(entity.ProfileImageUrl))
                await _blobService.DeleteUserImageAsync(entity.ProfileImageUrl);

            entity.ProfileImageUrl = newUrl;
        }

        entity.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);

        entity = await GetUserWithRoleAsync(id, cancellationToken);
        return _mapper.Map<UserResponse>(entity);
    }

    public override async Task<UserResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await GetUserWithRoleAsync(id, cancellationToken);
        if (entity == null)
            return null;

        return _mapper.Map<UserResponse>(entity);
    }

    public async Task<User?> GetEntityByUsername(string username, CancellationToken ct)
    {
        return await _context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Username == username, ct);
    }
    public async Task<UserResponse?> AuthenticateUser(UserLoginRequest request, CancellationToken cancellationToken = default)
    {
        var user = await _context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Username == request.Username, cancellationToken);

        if (user == null || string.IsNullOrEmpty(user.PasswordHash))
            return null;

        bool verified = _passwordHasher.Verify(request.Password, user.PasswordHash);
        if (!verified)
            return null;

        if (!user.IsActive)
            throw new BusinessException("Your account has been deactivated.");

        return _mapper.Map<UserResponse>(user);
    }

    public async Task<UserResponse?> AuthenticateAdmin(UserLoginRequest request, CancellationToken ct = default)
    {
        var user = await _context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Username.ToLower() == request.Username.ToLower(), ct);

        if (user == null)
            throw new NotFoundException("User not found");

        if (!_passwordHasher.Verify(request.Password, user.PasswordHash))
            return null;

        if (!user.IsActive)
            throw new BusinessException("Your account has been deactivated.");

        if (user.Role?.Name != Roles.Admin)
            throw new UnauthorizedAccessException("Access denied. User is not an admin.");

        return _mapper.Map<UserResponse>(user);
    }


    public async Task<UserResponse> RegisterAsync(UserInsertRequest request, CancellationToken ct)
    {
        request.Username = request.Username.Trim();
        request.Email = request.Email.Trim();

        bool usernameExists = await _context.Users
            .AnyAsync(u => u.Username == request.Username, ct);

        if (usernameExists)
            throw new BusinessException("Username already exists.");

        bool emailExists = await _context.Users
            .AnyAsync(u => u.Email == request.Email, ct);

        if (emailExists)
            throw new BusinessException("Email already exists.");

        var clientRole = await _context.Roles
            .FirstOrDefaultAsync(r => r.Name == Roles.Client, ct);

        if (clientRole == null)
            throw new BusinessException("Client role is not configured.");

        request.RoleId = clientRole.Id;
        request.IsActive = true;

        return await CreateAsync(request, ct);
    }


    public async Task<ForgotPasswordResponse> RequestPasswordResetAsync(ForgotPasswordRequest request, CancellationToken ct = default)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email, ct);
        if (user == null)
        {
            return new ForgotPasswordResponse
            {
                Success = true,
                Message = "If the email exists, a reset code has been sent."
            };
        }

        var existingResets = await _context.PasswordResets
            .Where(pr => pr.UserId == user.Id && !pr.IsUsed && pr.ExpiresAt > DateTime.UtcNow)
            .ToListAsync(ct);

        foreach (var reset in existingResets)
        {
            reset.IsUsed = true;
            reset.UsedAt = DateTime.UtcNow;
        }

        var resetCode = GenerateResetCode();
        var expiresAt = DateTime.UtcNow.AddMinutes(15);
        var resetCodeHash = _passwordHasher.Hash(resetCode);

        var passwordReset = new PasswordReset
        {
            UserId = user.Id,
            Email = user.Email,
            ResetCode = resetCodeHash,
            AttemptCount = 0,
            ExpiresAt = expiresAt
        };

        _context.PasswordResets.Add(passwordReset);
        await _context.SaveChangesAsync(ct);

        var message = new PasswordResetRequested
        {
            UserId = user.Id,
            UserName = $"{user.FirstName} {user.LastName}",
            UserEmail = user.Email,
            ResetCode = resetCode,
            RequestedAt = DateTime.UtcNow,
            ExpiresAt = expiresAt
        };

        await _rabbitMQService.PublishAsync(message, "meetspace.password-reset");

        return new ForgotPasswordResponse
        {
            Success = true,
            Message = "If the email exists, a reset code has been sent."
        };
    }

    public async Task<ForgotPasswordResponse> ResetPasswordAsync(ResetPasswordRequest request, CancellationToken ct = default)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email, ct);
        if (user == null)
        {
            return new ForgotPasswordResponse
            {
                Success = false,
                Message = "Invalid reset code or email."
            };
        }

        var passwordReset = await _context.PasswordResets
     .Where(pr =>
         pr.UserId == user.Id &&
         pr.Email == request.Email &&
         !pr.IsUsed &&
         pr.ExpiresAt > DateTime.UtcNow)
     .OrderByDescending(pr => pr.CreatedAt)
     .FirstOrDefaultAsync(ct);

        if (passwordReset == null)
        {
            return new ForgotPasswordResponse
            {
                Success = false,
                Message = "Invalid or expired reset code."
            };
        }

        if (passwordReset.AttemptCount >= MaxPasswordResetAttempts)
        {
            passwordReset.IsUsed = true;
            passwordReset.UsedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync(ct);

            return new ForgotPasswordResponse
            {
                Success = false,
                Message = "Invalid or expired reset code."
            };
        }

        if (!_passwordHasher.Verify(request.ResetCode, passwordReset.ResetCode))
        {
            passwordReset.AttemptCount++;

            if (passwordReset.AttemptCount >= MaxPasswordResetAttempts)
            {
                passwordReset.IsUsed = true;
                passwordReset.UsedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync(ct);

            return new ForgotPasswordResponse
            {
                Success = false,
                Message = "Invalid or expired reset code."
            };
        }

        user.PasswordHash = _passwordHasher.Hash(request.NewPassword);
        user.UpdatedAt = DateTime.UtcNow;

        passwordReset.IsUsed = true;
        passwordReset.UsedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(ct);

        return new ForgotPasswordResponse
        {
            Success = true,
            Message = "Password has been reset successfully."
        };
    }

    private string GenerateResetCode()
    {
        return RandomNumberGenerator
            .GetInt32(100000, 1000000)
            .ToString();
    }

    public async Task<bool> IsTokenRevokedAsync(string jti, CancellationToken ct = default)
    {
        return await _context.RevokedTokens
            .AnyAsync(x => x.Jti == jti && x.ExpiresAt > DateTime.UtcNow, ct);
    }

    public async Task RevokeTokenAsync(string jti, DateTime expiresAt, CancellationToken ct = default)
    {
        _context.RevokedTokens.Add(new RevokedToken
        {
            Jti = jti,
            ExpiresAt = expiresAt
        });

        await _context.SaveChangesAsync(ct);
    }


}
