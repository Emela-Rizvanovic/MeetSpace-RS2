using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Services.Security
{
    public interface IPasswordHasher
    {
        // Returns a PBKDF2 hash that already contains the iteration count and salt.
        string Hash(string password);

        // Checks a plain password against a previously‑produced hash.
        bool Verify(string password, string storedHash);
    }
}
