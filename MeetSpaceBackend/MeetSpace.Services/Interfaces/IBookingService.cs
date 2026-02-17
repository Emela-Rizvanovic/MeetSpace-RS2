using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseInterfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Services.Interfaces
{
    public interface IBookingService : ICRUDService<BookingResponse, BookingSearchObject, BookingInsertRequest, BookingUpdateRequest>
    {
        Task<List<BookingResponse>> GetByUserIdAsync(int userId, CancellationToken ct = default);
    }
}
