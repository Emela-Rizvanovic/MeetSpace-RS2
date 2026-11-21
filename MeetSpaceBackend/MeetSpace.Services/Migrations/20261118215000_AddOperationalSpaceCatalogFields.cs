using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MeetSpace.Services.Migrations
{
    public partial class AddOperationalSpaceCatalogFields : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "SpaceCode",
                table: "Spaces",
                type: "nvarchar(40)",
                maxLength: 40,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PriceBasis",
                table: "Spaces",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "Simulated");

            migrationBuilder.AddColumn<string>(
                name: "PriceSource",
                table: "Spaces",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PriceNotes",
                table: "Spaces",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Spaces_SpaceCode",
                table: "Spaces",
                column: "SpaceCode",
                unique: true,
                filter: "[SpaceCode] IS NOT NULL");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(name: "IX_Spaces_SpaceCode", table: "Spaces");
            migrationBuilder.DropColumn(name: "SpaceCode", table: "Spaces");
            migrationBuilder.DropColumn(name: "PriceBasis", table: "Spaces");
            migrationBuilder.DropColumn(name: "PriceSource", table: "Spaces");
            migrationBuilder.DropColumn(name: "PriceNotes", table: "Spaces");
        }
    }
}
