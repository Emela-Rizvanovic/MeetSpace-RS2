using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace MeetSpace.Services.Services
{
    public class RevenueService
        : BaseService<RevenueResponse, RevenueSearchObject, Payment>,
          IRevenueService
    {
        public RevenueService(MeetSpaceDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<Payment> ApplyFilter(
            IQueryable<Payment> query,
            RevenueSearchObject search)
        {

          

            query = query
                .Include(p => p.User)
                .Include(p => p.PaymentMethod)
                .Include(p => p.Booking)
                    .ThenInclude(b => b.Space)
                        .ThenInclude(s => s.Facility);

            /// 🔍 SEARCH
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(p =>
                    p.Booking.Space.Name.Contains(search.Name)
                );
            }

            /// 📅 DATE FILTER
            if (search.FromDate.HasValue)
            {
                query = query.Where(p => p.PaymentDate >= search.FromDate.Value);
            }

            if (search.ToDate.HasValue)
            {
                query = query.Where(p => p.PaymentDate <= search.ToDate.Value);
            }

            /// 🔥 SORT (isti kao kod ostalih)
            query = base.ApplyFilter(query, search);

            return query;
        }

        protected override RevenueResponse MapToResponse(Payment entity)
        {
            return new RevenueResponse
            {
                Amount = entity.Amount,
                User = entity.User.FirstName + " " + entity.User.LastName,
                Location = entity.Booking.Space.Facility.Name + " - " + entity.Booking.Space.Name,
                PaymentMethod = entity.PaymentMethod.Name,
                Date = entity.PaymentDate
            };
        }

        public async Task<List<RevenueResponse>> GetLatest()
        {
            return await _context.Payments
                .Include(p => p.User)
                .Include(p => p.PaymentMethod)
                .Include(p => p.Booking)
                    .ThenInclude(b => b.Space)
                        .ThenInclude(s => s.Facility)
                .OrderByDescending(p => p.PaymentDate)
                .Take(3)
                .Select(p => new RevenueResponse
                {
                    Amount = p.Amount,
                    User = p.User.FirstName + " " + p.User.LastName,
                    Location = p.Booking.Space.Facility.Name + " - " + p.Booking.Space.Name,
                    PaymentMethod = p.PaymentMethod.Name,
                    Date = p.PaymentDate
                })
                .ToListAsync();
        }

        public async Task<double> GetTotal()
        {
            return await _context.Payments.SumAsync(p => (double)p.Amount);
        }
    }
}