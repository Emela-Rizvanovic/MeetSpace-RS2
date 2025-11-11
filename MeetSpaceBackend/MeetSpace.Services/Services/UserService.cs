using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

public class UserService : BaseCRUDService<UserResponse, UserSearchObject, User, UserInsertRequest, UserUpdateRequest>, IUserService
{
    public UserService(MeetSpaceDbContext context, IMapper mapper)
        : base(context, mapper)
    {
    }

    // ApplyFilter ostaje isto
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

        entity.PasswordHash = request.Password;
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

        _context.Users.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);

        // Ponovo učitaj entity s Role preko privatne metode
        entity = await GetUserWithRoleAsync(entity.Id, cancellationToken);
        return _mapper.Map<UserResponse>(entity);
    }

    public override async Task<UserResponse?> UpdateAsync(int id, UserUpdateRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await GetUserWithRoleAsync(id, cancellationToken);
        if (entity == null)
            return null;

        await BeforeUpdate(entity, request, cancellationToken);

        _mapper.Map(request, entity);
        await _context.SaveChangesAsync(cancellationToken);

        // Ponovo učitaj entity s Role da RoleName bude popunjeno
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
}
