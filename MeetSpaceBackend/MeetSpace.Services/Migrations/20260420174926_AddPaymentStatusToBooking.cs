using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MeetSpace.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddPaymentStatusToBooking : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "PaymentStatusId",
                table: "Bookings",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_PaymentStatusId",
                table: "Bookings",
                column: "PaymentStatusId");

            migrationBuilder.AddForeignKey(
                name: "FK_Bookings_PaymentStatuses_PaymentStatusId",
                table: "Bookings",
                column: "PaymentStatusId",
                principalTable: "PaymentStatuses",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Bookings_PaymentStatuses_PaymentStatusId",
                table: "Bookings");

            migrationBuilder.DropIndex(
                name: "IX_Bookings_PaymentStatusId",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "PaymentStatusId",
                table: "Bookings");
        }
    }
}
