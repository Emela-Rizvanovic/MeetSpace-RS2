using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.Responses
{
    public class RevenueResponse
    {
        public decimal Amount { get; set; }
        public string User { get; set; }
        public string Location { get; set; }
        public string PaymentMethod { get; set; }
        public DateTime Date { get; set; }
    }
}
