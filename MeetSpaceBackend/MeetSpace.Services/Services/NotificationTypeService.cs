using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Enums;
using MeetSpace.Models.Exceptions;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace MeetSpace.Services.Services
{
    public class NotificationTypeService
        : CachedReferenceCRUDService<NotificationTypeResponse, NotificationTypeSearchObject, NotificationType, NotificationTypeInsertRequest, NotificationTypeUpdateRequest>,
          INotificationTypeService
    {
        public NotificationTypeService(MeetSpaceDbContext context, IMapper mapper, IMemoryCache cache)
            : base(context, mapper, cache)
        {
        }

        protected override IQueryable<NotificationType> ApplyFilter(IQueryable<NotificationType> query, NotificationTypeSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(x => x.Name.Contains(search.Name));

            return query;
        }

        protected override async Task BeforeInsert(NotificationType entity, NotificationTypeInsertRequest request, CancellationToken cancellationToken = default)
        {
            var exists = await _context.NotificationTypes.AnyAsync(x => x.Name.ToLower() == request.Name.ToLower(), cancellationToken);
            if (exists)
                throw new BusinessException("Notification type with this name already exists.");

            await base.BeforeInsert(entity, request, cancellationToken);
        }

        protected override async Task BeforeUpdate(NotificationType entity, NotificationTypeUpdateRequest request, CancellationToken cancellationToken = default)
        {
            if (!string.IsNullOrWhiteSpace(request.Name))
            {
                var exists = await _context.NotificationTypes.AnyAsync(
                    x => x.Id != entity.Id && x.Name.ToLower() == request.Name.ToLower(),
                    cancellationToken);

                if (exists)
                    throw new BusinessException("Notification type with this name already exists.");
            }

            await base.BeforeUpdate(entity, request, cancellationToken);
        }

        protected override async Task BeforeDelete(NotificationType entity, CancellationToken cancellationToken = default)
        {
            var isSystemValue = Enum.IsDefined(typeof(NotificationTypeEnum), entity.Id);
            if (isSystemValue)
                throw new BusinessException("System notification types are required by the notification workflow and cannot be deleted.");

            var isUsed = await _context.Notifications.AnyAsync(x => x.NotificationTypeId == entity.Id, cancellationToken);
            if (isUsed)
                throw new BusinessException("Cannot delete notification type because it is used by existing notifications.");

            await base.BeforeDelete(entity, cancellationToken);
        }
    }
}