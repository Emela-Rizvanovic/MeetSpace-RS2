using MeetSpace.Services.Database;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MeetSpace.WebAPI.Controllers
{
    [ApiController]
    [Authorize(Roles = "Admin")]
    [Route("api/[controller]")]
    public class RevenueController : ControllerBase
    {
        private readonly MeetSpaceDbContext _context;

        public RevenueController(MeetSpaceDbContext context)
        {
            _context = context;
        }

        [HttpGet("latest")]
        public async Task<IActionResult> GetLatest()
        {
            var data = await _context.Payments
                .Include(p => p.User)
                .Include(p => p.PaymentMethod)
                .Include(p => p.Booking)
                    .ThenInclude(b => b.Space)
                        .ThenInclude(s => s.Facility)
                .OrderByDescending(p => p.PaymentDate)
                .Take(3)
                .Select(p => new
                {
                    amount = p.Amount,
                    user = p.User.FirstName + " " + p.User.LastName,
                    location = p.Booking.Space.Facility.Name + " - " + p.Booking.Space.Name,
                    paymentMethod = p.PaymentMethod.Name,
                    date = p.PaymentDate
                })
                .ToListAsync();

            return Ok(data);
        }

        [HttpGet("all")]
        public async Task<IActionResult> GetAll()
        {
            var data = await _context.Payments
                .Include(p => p.User)
                .Include(p => p.PaymentMethod)
                .Include(p => p.Booking)
                    .ThenInclude(b => b.Space)
                        .ThenInclude(s => s.Facility)
                .OrderByDescending(p => p.PaymentDate)
                .Select(p => new
                {
                    amount = p.Amount,
                    user = p.User.FirstName + " " + p.User.LastName,
                    location = p.Booking.Space.Facility.Name + " - " + p.Booking.Space.Name,
                    paymentMethod = p.PaymentMethod.Name,
                    date = p.PaymentDate
                })
                .ToListAsync();

            return Ok(data);
        }

        [HttpGet("total")]
        public async Task<IActionResult> GetTotal()
        {
            var total = await _context.Payments
                .SumAsync(p => p.Amount);

            return Ok(total);
        }
    }
}