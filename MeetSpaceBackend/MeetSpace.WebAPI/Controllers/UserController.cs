using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.Interfaces;
using MeetSpace.Services.Security;
using MeetSpace.WebAPI.BaseControllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MeetSpace.WebAPI.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class UserController : BaseCRUDController<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        private readonly IUserService _userService;
        private readonly IJwtTokenService _jwtTokenService;

        public UserController(IUserService service, IJwtTokenService jwtTokenService)
    : base(service)
        {
            _userService = service;
            _jwtTokenService = jwtTokenService;
        }

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<ActionResult<LoginResponse>> Login(
    UserLoginRequest request,
    CancellationToken cancellationToken)
        {
            var userResponse = await _userService
                .AuthenticateUser(request, cancellationToken);

            if (userResponse == null)
                return Unauthorized("Invalid username or password.");

            var userEntity = await _userService
                .GetEntityByUsername(request.Username, cancellationToken);

            var token = _jwtTokenService.GenerateToken(userEntity);

            return Ok(new LoginResponse
            {
                Token = token,
                User = userResponse
            });
        }

        [AllowAnonymous]
        [HttpPost("admin-login")]
        public async Task<ActionResult<LoginResponse>> AdminLogin(
    [FromBody] UserLoginRequest request,
    CancellationToken ct)
        {
            try
            {
                var userResponse = await _userService.AuthenticateAdmin(request, ct);

                if (userResponse == null)
                    return Unauthorized("Invalid credentials.");

                var userEntity = await _userService
                    .GetEntityByUsername(request.Username, ct);

                var token = _jwtTokenService.GenerateToken(userEntity);

                return Ok(new LoginResponse
                {
                    Token = token,
                    User = userResponse
                });
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
        [Authorize(Roles = "Admin")]
        [Consumes("multipart/form-data")]
        public override Task<UserResponse> Create([FromForm] UserInsertRequest request)
        {
            return base.Create(request);
        }

        [HttpPut("{id}")]
        [Consumes("multipart/form-data")]
        public override async Task<UserResponse?> Update(
    int id,
    [FromForm] UserUpdateRequest request)
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            var roleClaim = User.FindFirst(System.Security.Claims.ClaimTypes.Role);

            if (userIdClaim == null || roleClaim == null)
                throw new UnauthorizedAccessException("Unauthorized.");

            int currentUserId = int.Parse(userIdClaim.Value);
            string currentRole = roleClaim.Value;

            if (currentRole != "Admin" && currentUserId != id)
                throw new UnauthorizedAccessException("You are not allowed to update this user.");

            if (currentRole != "Admin")
            {
                request.RoleId = null;
            }

            return await base.Update(id, request);
        }


<<<<<<< Updated upstream
        // TO-DO 
        // azurirati ga kao i sve kad dodje vrijeme
=======
        [AllowAnonymous]
        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request, CancellationToken ct)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            try
            {
                var result = await _userService.RequestPasswordResetAsync(request, ct);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { Message = "An error occurred while processing your request." });
            }
        }

        [AllowAnonymous]
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request, CancellationToken ct)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            try
            {
                var result = await _userService.ResetPasswordAsync(request, ct);
                if (result.Success)
                    return Ok(result);
                else
                    return BadRequest(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { Message = "An error occurred while processing your request." });
            }
        }

        [Authorize(Roles = "Admin")]
        [HttpGet]
        public override Task<PagedResult<UserResponse>> Get([FromQuery] UserSearchObject search)
        {
            return base.Get(search);
        }

        [Authorize(Roles = "Admin")]
        [HttpGet("{id}")]
        public override Task<UserResponse?> GetById(int id)
        {
            return base.GetById(id);
        }

        [HttpGet("me")]
        public async Task<ActionResult<UserResponse>> GetCurrentUser(CancellationToken ct)
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
                return Unauthorized();

            int userId = int.Parse(userIdClaim.Value);

            var user = await _userService.GetByIdAsync(userId, ct);

            return Ok(user);
        }
>>>>>>> Stashed changes
    }
}
