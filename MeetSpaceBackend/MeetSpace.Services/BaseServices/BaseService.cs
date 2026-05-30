using AutoMapper;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseInterfaces;
using MeetSpace.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace MeetSpace.Services.BaseServices
{
    public abstract class BaseService<T, TSearch, TEntity> :
     IService<T, TSearch>
         where T : class
         where TSearch : BaseSearchObject
         where TEntity : class
    {
        protected readonly MeetSpaceDbContext _context;
        protected readonly IMapper _mapper;

        public BaseService(MeetSpaceDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public virtual async Task<PagedResult<T>> GetAsync(
     TSearch search,
     CancellationToken cancellationToken = default)
        {
            var query = _context.Set<TEntity>().AsQueryable();

            query = ApplyFilter(query, search);
            query = ApplySort(query, search);

            var totalCount = await query.CountAsync(cancellationToken);

            var page = search.Page ?? 0;
            var pageSize = search.PageSize ?? BaseSearchObject.DefaultPageSize;

            if (page < 0)
                page = 0;

            if (pageSize <= 0)
                pageSize = BaseSearchObject.DefaultPageSize;

            if (pageSize > BaseSearchObject.MaxPageSize)
                pageSize = BaseSearchObject.MaxPageSize;

            query = query
                .Skip(page * pageSize)
                .Take(pageSize);

            var list = await query.ToListAsync(cancellationToken);

            return new PagedResult<T>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        protected virtual IQueryable<TEntity> ApplyFilter(IQueryable<TEntity> query, TSearch search)
        {
            return query;
        }

        protected virtual IQueryable<TEntity> ApplySort(IQueryable<TEntity> query, TSearch search)
        {

            if (string.IsNullOrWhiteSpace(search.SortBy))
                return query;

            if (search.Desc)
                return query.OrderByDescending(e => EF.Property<object>(e, search.SortBy));

            return query.OrderBy(e => EF.Property<object>(e, search.SortBy));
        }

        public virtual async Task<T?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var entity = await _context.Set<TEntity>().FindAsync(new object[] { id }, cancellationToken);
            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        protected virtual T MapToResponse(TEntity entity)
        {
            return _mapper.Map<T>(entity);
        }

    }
}
