using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System;
using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class BookingInsertRequest
    {
        [Required]
        public int SpaceId { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        public int BookingStatusId { get; set; }

        [Required]
        public DateTime StartTime { get; set; }

        [Required]
        public DateTime EndTime { get; set; }

        // Servis će ovo izračunati (Space.PricePerHour * trajanje)
        //public decimal TotalPrice { get; set; }
    }
}

