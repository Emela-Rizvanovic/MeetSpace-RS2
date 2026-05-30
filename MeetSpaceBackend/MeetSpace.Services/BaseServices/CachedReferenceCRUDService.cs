using AutoMapper;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.Database;
using Microsoft.Extensions.Caching.Memory;
using System.Text.Json;

namespace MeetSpace.Services.BaseServices
{
    public abstract class CachedReferenceCRUDService<T, TSearch, TEntity, TInsert, TUpdate>
        : BaseCRUDService<T, TSearch, TEntity, TInsert, TUpdate>
        where T : class
        where TSearch : BaseSearchObject
        where TEntity : class, new()
        where TInsert : class
        where TUpdate : class
    {
        private readonly IMemoryCache _cache;
        private readonly string _cachePrefix;

        protected CachedReferenceCRUDService(
            MeetSpaceDbContext context,
            IMapper mapper,
            IMemoryCache cache)
            : base(context, mapper)
        {
            _cache = cache;
            _cachePrefix = typeof(TEntity).Name;
        }

        public override async Task<PagedResult<T>> GetAsync(
            TSearch search,
            CancellationToken cancellationToken = default)
        {
            var cacheKey = $"{_cachePrefix}:{JsonSerializer.Serialize(search)}";

            if (_cache.TryGetValue(cacheKey, out PagedResult<T>? cached) &&
                cached != null)
            {
                return cached;
            }

            var result = await base.GetAsync(search, cancellationToken);

            _cache.Set(
                cacheKey,
                result,
                TimeSpan.FromMinutes(5));

            return result;
        }

        public override async Task<T> CreateAsync(
            TInsert request,
            CancellationToken cancellationToken = default)
        {
            var result = await base.CreateAsync(request, cancellationToken);
            ClearCache();
            return result;
        }

        public override async Task<T?> UpdateAsync(
            int id,
            TUpdate request,
            CancellationToken cancellationToken = default)
        {
            var result = await base.UpdateAsync(id, request, cancellationToken);
            ClearCache();
            return result;
        }

        public override async Task<bool> DeleteAsync(
            int id,
            CancellationToken cancellationToken = default)
        {
            var result = await base.DeleteAsync(id, cancellationToken);
            ClearCache();
            return result;
        }

        private void ClearCache()
        {
            if (_cache is MemoryCache memoryCache)
            {
                memoryCache.Compact(1.0);
            }
        }
    }
}