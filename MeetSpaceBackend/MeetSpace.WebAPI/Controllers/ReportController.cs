using MeetSpace.Models.Constants;
using MeetSpace.Services.Database;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Authorize(Roles = Roles.Admin)]
[Route("api/[controller]")]
public class ReportController : ControllerBase
{
    private readonly MeetSpaceDbContext _context;

    public ReportController(MeetSpaceDbContext context)
    {
        _context = context;
    }

    [HttpGet("revenue")]
    public async Task<IActionResult> GenerateRevenueReport()
    {
        var payments = await _context.Payments
            .Include(p => p.User)
            .Include(p => p.Booking)
                .ThenInclude(b => b.Space)
            .Include(p => p.PaymentMethod)
            .OrderByDescending(p => p.PaymentDate)
            .ToListAsync();

        // TODO: generisanje PDF-a (idemo korak po korak)

        return Ok(payments);
    }
}