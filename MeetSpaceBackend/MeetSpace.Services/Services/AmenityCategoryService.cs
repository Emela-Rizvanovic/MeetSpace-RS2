using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Services.Services
{
    public class AmenityCategoryService 
        : BaseCRUDService<AmenityCategoryResponse, AmenityCategorySearchObject, AmenityCategory, AmenityCategoryInsertRequest, AmenityCategoryUpdateRequest>,
        IAmenityCategoryService
    {
        public AmenityCategoryService(MeetSpaceDbContext context, IMapper mapper) 
            : base (context, mapper)
        { 
        }

        // Filter za pretragu po nazivu
        protected override IQueryable<AmenityCategory> ApplyFilter(IQueryable<AmenityCategory> query, AmenityCategorySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }

            return query;
        }

        // protected override async Task BeforeUpdate(...) { } ?
    }
}
