using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.Extensions.Caching.Memory;
using MeetSpace.Models.Enums;
using MeetSpace.Models.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace MeetSpace.Services.Services
{
    public class PaymentStatusService
 : CachedReferenceCRUDService<PaymentStatusResponse, PaymentStatusSearchObject, PaymentStatus, PaymentStatusInsertRequest, PaymentStatusUpdateRequest>,
   IPaymentStatusService
    {
        public PaymentStatusService(MeetSpaceDbContext context, IMapper mapper, IMemoryCache cache)
            : base(context, mapper, cache)
        {
        }

        protected override IQueryable<PaymentStatus> ApplyFilter(IQueryable<PaymentStatus> query, PaymentStatusSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }

            return query;
        }

        protected override async Task BeforeDelete(PaymentStatus entity, CancellationToken cancellationToken = default)
        {
            var isSystemValue = Enum.IsDefined(typeof(PaymentStatusEnum), entity.Id);
            if (isSystemValue)
                throw new BusinessException("System payment statuses are required by the payment workflow and cannot be deleted.");

            var isUsed = await _context.Payments.AnyAsync(x => x.PaymentStatusId == entity.Id, cancellationToken)
                || await _context.Bookings.AnyAsync(x => x.PaymentStatusId == entity.Id, cancellationToken);

            if (isUsed)
                throw new BusinessException("Cannot delete payment status because it is used by existing payments or bookings.");

            await base.BeforeDelete(entity, cancellationToken);
        }

    }
}
