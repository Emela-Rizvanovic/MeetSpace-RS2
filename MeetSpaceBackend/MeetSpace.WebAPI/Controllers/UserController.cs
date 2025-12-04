using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.Interfaces;
using MeetSpace.WebAPI.BaseControllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MeetSpace.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : BaseCRUDController<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        private readonly IUserService _userService;

        public UserController(IUserService service) : base(service)
        {
            _userService = service;
        }

        [AllowAnonymous] 
        [HttpPost("login")]
        public async Task<ActionResult<UserResponse>> Login(UserLoginRequest request, CancellationToken cancellationToken)
        {
            var user = await _userService.AuthenticateUser(request, cancellationToken);

            if (user == null)
                return Unauthorized("Invalid username or password.");

            return Ok(user);
        }

        [AllowAnonymous]
        [HttpPost("admin-login")]
        public async Task<ActionResult<UserResponse>> AdminLogin([FromBody] UserLoginRequest request, CancellationToken ct)
        {
            try
            {
                var user = await _userService.AuthenticateAdmin(request, ct);
                return Ok(user);
            }
            catch (Exception ex)
            {
                return Unauthorized(ex.Message);
            }
        }

        [AllowAnonymous]
        [HttpPost("register")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Register([FromForm] UserInsertRequest request, CancellationToken ct)
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState.Values.SelectMany(v => v.Errors)
                    .Select(e => e.ErrorMessage).ToList();
                return BadRequest(errors);
            }

            try
            {
                var response = await _userService.RegisterAsync(request, ct);
                return CreatedAtAction(nameof(GetById), new { id = response.Id }, response);
            }
            catch (ArgumentException ex)
            {
                return Conflict(ex.Message);
            }
        }


        [HttpPost]
        [Consumes("multipart/form-data")]
        public override Task<UserResponse> Create([FromForm] UserInsertRequest request)
        {
            return base.Create(request);
        }

        [HttpPut("{id}")]
        [Consumes("multipart/form-data")]
        public override Task<UserResponse?> Update(int id, [FromForm] UserUpdateRequest request)
        {
            return base.Update(id, request);
        }


        // TO-DO 
        // azurirati ga kao i sve kad dodje vrijeme
    }
}
