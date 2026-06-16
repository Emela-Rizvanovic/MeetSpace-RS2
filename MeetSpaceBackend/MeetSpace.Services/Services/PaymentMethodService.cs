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
    public class PaymentMethodService
    : CachedReferenceCRUDService<PaymentMethodResponse, PaymentMethodSearchObject, PaymentMethod, PaymentMethodInsertRequest, PaymentMethodUpdateRequest>,
      IPaymentMethodService
    {
        public PaymentMethodService(MeetSpaceDbContext context, IMapper mapper, IMemoryCache cache)
            : base(context, mapper, cache)
        {
        }
        protected override IQueryable<PaymentMethod> ApplyFilter(IQueryable<PaymentMethod> query, PaymentMethodSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }

            return query;
        }

        protected override async Task BeforeDelete(PaymentMethod entity, CancellationToken cancellationToken = default)
        {
            var isSystemValue = Enum.IsDefined(typeof(PaymentMethodEnum), entity.Id);
            if (isSystemValue)
                throw new BusinessException("System payment methods are required by the payment workflow and cannot be deleted.");

            var isUsed = await _context.Payments.AnyAsync(x => x.PaymentMethodId == entity.Id, cancellationToken);
            if (isUsed)
                throw new BusinessException("Cannot delete payment method because it is used by existing payments.");

            await base.BeforeDelete(entity, cancellationToken);
        }
    }
}
