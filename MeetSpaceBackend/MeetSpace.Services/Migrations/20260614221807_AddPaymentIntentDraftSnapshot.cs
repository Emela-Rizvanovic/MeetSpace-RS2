using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MeetSpace.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddPaymentIntentDraftSnapshot : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AmenitiesSnapshotJson",
                table: "PaymentIntents",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "EndTime",
                table: "PaymentIntents",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "ExpiresAt",
                table: "PaymentIntents",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<string>(
                name: "Provider",
                table: "PaymentIntents",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ProviderOrderId",
                table: "PaymentIntents",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SpaceId",
                table: "PaymentIntents",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "StartTime",
                table: "PaymentIntents",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "PaymentIntents",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "UserId",
                table: "PaymentIntents",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AmenitiesSnapshotJson",
                table: "PaymentIntents");

            migrationBuilder.DropColumn(
                name: "EndTime",
                table: "PaymentIntents");

            migrationBuilder.DropColumn(
                name: "ExpiresAt",
                table: "PaymentIntents");

            migrationBuilder.DropColumn(
                name: "Provider",
                table: "PaymentIntents");

            migrationBuilder.DropColumn(
                name: "ProviderOrderId",
                table: "PaymentIntents");

            migrationBuilder.DropColumn(
                name: "SpaceId",
                table: "PaymentIntents");

            migrationBuilder.DropColumn(
                name: "StartTime",
                table: "PaymentIntents");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "PaymentIntents");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "PaymentIntents");
        }
    }
}
