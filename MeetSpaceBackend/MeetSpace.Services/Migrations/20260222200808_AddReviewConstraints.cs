using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MeetSpace.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddReviewConstraints : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Reviews_UserId",
                table: "Reviews");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_UserId_SpaceId",
                table: "Reviews",
                columns: new[] { "UserId", "SpaceId" },
                unique: true);

            migrationBuilder.AddCheckConstraint(
                name: "CK_Review_Rating",
                table: "Reviews",
                sql: "[Rating] >= 1 AND [Rating] <= 5");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Reviews_UserId_SpaceId",
                table: "Reviews");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Review_Rating",
                table: "Reviews");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_UserId",
                table: "Reviews",
                column: "UserId");
        }
    }
}
