using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using MeetSpace.Services.Security;
using Microsoft.EntityFrameworkCore;
using System.Threading;

public class UserService : BaseCRUDService<UserResponse, UserSearchObject, User, UserInsertRequest, UserUpdateRequest>, IUserService
{
    private readonly IPasswordHasher _passwordHasher;
    private readonly IBlobService _blobService;

    public UserService(MeetSpaceDbContext context, IMapper mapper, IPasswordHasher passwordHasher, IBlobService blobService)
        : base(context, mapper)
    {
        _passwordHasher = passwordHasher;
        _blobService = blobService;
    }
    
    protected override IQueryable<User> ApplyFilter(IQueryable<User> query, UserSearchObject search)
    {
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
        var existing = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email, cancellationToken);
        if (existing != null)
            throw new Exception("Email already exists.");

        entity.PasswordHash = _passwordHasher.Hash(request.Password);
        entity.CreatedAt = DateTime.UtcNow;

        await base.BeforeInsert(entity, request, cancellationToken);
    }

    protected override async Task BeforeUpdate(User entity, UserUpdateRequest request, CancellationToken cancellationToken = default)
    {
        entity.UpdatedAt = DateTime.UtcNow;
        await base.BeforeUpdate(entity, request, cancellationToken);
    }

    // Privatna metoda koja učitava korisnika s Role
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
            entity.PasswordHash = _passwordHasher.Hash(request.Password);

        // Upload nove slike samo ako je zaista poslana (file != null && ima sadržaj)
        if (request.ProfileImageUrl != null && request.ProfileImageUrl.Length > 0)
        {
            // Upload nove slike
            var newUrl = await _blobService.UploadUserImageAsync(request.ProfileImageUrl);

            // Brisanje stare slike da se ne zauzima storage
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

        // Uspješna prijava mapira i vrati korisnika
        return _mapper.Map<UserResponse>(user);
    }

    public async Task<UserResponse> AuthenticateAdmin(UserLoginRequest request, CancellationToken ct = default)
    {
        var user = await _context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Username.ToLower() == request.Username.ToLower(), ct);

        if (user == null)
            throw new Exception("User not found");

        if (!_passwordHasher.Verify(request.Password, user.PasswordHash))
            return null;

        // provjera da li je user admin
        if (user.Role?.Name?.ToLower() != "admin")
            throw new Exception("Access denied. User is not an admin.");

        return _mapper.Map<UserResponse>(user);
    }


    public async Task<UserResponse> RegisterAsync(UserInsertRequest request, CancellationToken ct)
    {
        bool usernameExists = await _context.Users.AnyAsync(u => u.Username == request.Username, ct);
        if (usernameExists)
            throw new ArgumentException("Username already exists.");

        bool emailExists = await _context.Users.AnyAsync(u => u.Email == request.Email, ct);
        if (emailExists)
            throw new ArgumentException("Email already exists.");

        var userEntity = _mapper.Map<User>(request);

        userEntity.PasswordHash = _passwordHasher.Hash(request.Password);

        _context.Users.Add(userEntity);
        await _context.SaveChangesAsync(ct);

        userEntity = await GetUserWithRoleAsync(userEntity.Id, ct);
        return _mapper.Map<UserResponse>(userEntity);
    }

}
