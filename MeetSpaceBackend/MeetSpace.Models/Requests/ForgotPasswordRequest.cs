using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.Requests
{
    public class ForgotPasswordRequest
    {
        [Required, EmailAddress]
        public string Email { get; set; }
    }
}
