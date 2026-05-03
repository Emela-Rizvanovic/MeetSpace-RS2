using System;

namespace MeetSpace.Models.SearchObjects
{
    public class RevenueSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }  
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
    }
}