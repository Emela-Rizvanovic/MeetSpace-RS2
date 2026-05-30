namespace MeetSpace.Models.SearchObjects
{
    public class BaseSearchObject
    {
        public const int DefaultPageSize = 20;
        public const int MaxPageSize = 100;
        public int? Page { get; set; } = 0;
        public int? PageSize { get; set; } = DefaultPageSize;
        public string SortBy { get; set; } = "Id"; 
        public bool Desc { get; set; } = false;
        public bool IncludeTotalCount { get; set; } = true;
        public bool RetrieveAll { get; set; } = false;
    }
}
