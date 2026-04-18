using System;
using System.Collections.Generic;

namespace MeetSpace.Models.Requests
{
    public class PayPalCaptureRequest
    {
        public string OrderId { get; set; }
        public int SpaceId { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public List<BookingAmenityInsertRequest> Amenities { get; set; }
    }
}