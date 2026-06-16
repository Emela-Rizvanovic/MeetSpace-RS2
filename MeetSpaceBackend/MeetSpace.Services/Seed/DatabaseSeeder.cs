using MeetSpace.Models.Constants;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Enums;
using MeetSpace.Services.Database;
using MeetSpace.Services.Security;
using Microsoft.EntityFrameworkCore;

namespace MeetSpace.Services.Seed
{
    public static class DatabaseSeeder
    {
        public static async Task SeedAsync(
            MeetSpaceDbContext context,
            IPasswordHasher passwordHasher,
            CancellationToken ct = default)
        {
            if (await context.Roles.AnyAsync(ct))
                return;

            await SeedFixedDataAsync(context, ct);
            await SeedReferenceDataAsync(context, passwordHasher, ct);
        }

        private static async Task SeedFixedDataAsync(
            MeetSpaceDbContext context,
            CancellationToken ct)
        {
            await InsertWithIdentityAsync(
                context,
                "Roles",
                async () =>
                {
                    context.Roles.AddRange(
                        new Role { Id = 1, Name = Roles.Admin },
                        new Role { Id = 2, Name = Roles.Client }
                    );

                    await context.SaveChangesAsync(ct);
                });

            await InsertWithIdentityAsync(
                context,
                "BookingStatuses",
                async () =>
                {
                    context.BookingStatuses.AddRange(
                        new BookingStatus { Id = (int)BookingStatusEnum.Pending, Name = "Pending" },
                        new BookingStatus { Id = (int)BookingStatusEnum.Approved, Name = "Approved" },
                        new BookingStatus { Id = (int)BookingStatusEnum.Rejected, Name = "Rejected" },
                        new BookingStatus { Id = (int)BookingStatusEnum.Cancelled, Name = "Cancelled" }
                    );

                    await context.SaveChangesAsync(ct);
                });

            await InsertWithIdentityAsync(
                context,
                "PaymentStatuses",
                async () =>
                {
                    context.PaymentStatuses.AddRange(
                        new PaymentStatus { Id = (int)PaymentStatusEnum.Pending, Name = "Pending" },
new PaymentStatus { Id = (int)PaymentStatusEnum.Completed, Name = "Completed" },
new PaymentStatus { Id = (int)PaymentStatusEnum.Failed, Name = "Failed" },
new PaymentStatus { Id = (int)PaymentStatusEnum.Authorized, Name = "Authorized" }
                    );

                    await context.SaveChangesAsync(ct);
                });

            await InsertWithIdentityAsync(
                context,
                "PaymentMethods",
                async () =>
                {
                    context.PaymentMethods.AddRange(
                        new PaymentMethod { Id = (int)PaymentMethodEnum.Stripe, Name = "Stripe" },
                        new PaymentMethod { Id = (int)PaymentMethodEnum.PayPal, Name = "PayPal" }
                    );

                    await context.SaveChangesAsync(ct);
                });

            await InsertWithIdentityAsync(
                context,
                "NotificationTypes",
                async () =>
                {
                    context.NotificationTypes.AddRange(
     new NotificationType { Id = (int)NotificationTypeEnum.BookingApproved, Name = "BookingApproved" },
     new NotificationType { Id = (int)NotificationTypeEnum.BookingRejected, Name = "BookingRejected" },
     new NotificationType { Id = (int)NotificationTypeEnum.BookingReminder, Name = "BookingReminder" },
     new NotificationType { Id = (int)NotificationTypeEnum.BookingCancelled, Name = "BookingCancelled" },
     new NotificationType { Id = (int)NotificationTypeEnum.PaymentAuthorized, Name = "PaymentAuthorized" },
     new NotificationType { Id = (int)NotificationTypeEnum.PaymentCompleted, Name = "PaymentCompleted" },
     new NotificationType { Id = (int)NotificationTypeEnum.UserBookingCancelled, Name = "UserBookingCancelled" },
     new NotificationType { Id = (int)NotificationTypeEnum.BookingCreated, Name = "BookingCreated" }
 );

                    await context.SaveChangesAsync(ct);
                });
        }

        private static async Task SeedReferenceDataAsync(
     MeetSpaceDbContext context,
     IPasswordHasher passwordHasher,
     CancellationToken ct)
        {
            var bosnia = new Country
            {
                Name = "Bosnia and Herzegovina"
            };

            context.Countries.Add(bosnia);
            await context.SaveChangesAsync(ct);

            var mostar = new City
            {
                Name = "Mostar",
                CountryId = bosnia.Id
            };

            var sarajevo = new City
            {
                Name = "Sarajevo",
                CountryId = bosnia.Id
            };

            context.Cities.AddRange(mostar, sarajevo);
            await context.SaveChangesAsync(ct);

            var mepasMall = new Facility
            {
                Name = "Mepas Mall",
                Address = "Kardinala Stepinca bb",
                CityId = mostar.Id,
                Description = "Modern business facility in the center of Mostar.",
                ContactEmail = "info@mepas.ba",
                ContactPhone = "+387 36 123 456"
            };

            var intera = new Facility
            {
                Name = "Intera Technology Park",
                Address = "Bišće polje bb",
                CityId = mostar.Id,
                Description = "Technology park with coworking, lab and education spaces.",
                ContactEmail = "info@intera.ba",
                ContactPhone = "+387 36 327 972"
            };

            var oldTown = new Facility
            {
                Name = "Old Town Workspace",
                Address = "Onešćukova 12",
                CityId = mostar.Id,
                Description = "Small workspace close to Mostar Old Bridge.",
                ContactEmail = "hello@oldtownworkspace.ba",
                ContactPhone = "+387 61 222 333"
            };

            context.Facilities.AddRange(mepasMall, intera, oldTown);
            await context.SaveChangesAsync(ct);

            var conferenceRoom = new SpaceType
            {
                Name = "Conference Room"
            };

            var coworkingSpace = new SpaceType
            {
                Name = "Coworking Space"
            };

            var lab = new SpaceType
            {
                Name = "Lab"
            };

            var classroom = new SpaceType
            {
                Name = "Classroom"
            };

            var privateOffice = new SpaceType
            {
                Name = "Private Office"
            };

            context.SpaceTypes.AddRange(
                conferenceRoom,
                coworkingSpace,
                lab,
                classroom,
                privateOffice);

            await context.SaveChangesAsync(ct);

            var equipment = new AmenityCategory
            {
                Name = "Equipment"
            };

            var foodAndDrinks = new AmenityCategory
            {
                Name = "Food and Drinks"
            };

            var services = new AmenityCategory
            {
                Name = "Services"
            };

            context.AmenityCategories.AddRange(
                equipment,
                foodAndDrinks,
                services);

            await context.SaveChangesAsync(ct);

            var projector = new Amenity
            {
                Name = "Projector",
                Description = "HD projector for presentations and workshops.",
                Price = 10,
                AmenityCategoryId = equipment.Id
            };

            var whiteboard = new Amenity
            {
                Name = "Whiteboard",
                Description = "Whiteboard with markers.",
                Price = 5,
                AmenityCategoryId = equipment.Id
            };

            var soundSystem = new Amenity
            {
                Name = "Sound System",
                Description = "Audio setup for meetings and events.",
                Price = 20,
                AmenityCategoryId = equipment.Id
            };

            var coffee = new Amenity
            {
                Name = "Coffee",
                Description = "Coffee service for participants.",
                Price = 3,
                AmenityCategoryId = foodAndDrinks.Id
            };

            var catering = new Amenity
            {
                Name = "Catering",
                Description = "Light catering for meetings and events.",
                Price = 15,
                AmenityCategoryId = foodAndDrinks.Id
            };

            var technicalSupport = new Amenity
            {
                Name = "Technical Support",
                Description = "On-site technical assistance.",
                Price = 25,
                AmenityCategoryId = services.Id
            };

            var parking = new Amenity
            {
                Name = "Parking",
                Description = "Reserved parking space.",
                Price = 5,
                AmenityCategoryId = services.Id
            };

            context.Amenities.AddRange(
                projector,
                whiteboard,
                soundSystem,
                coffee,
                catering,
                technicalSupport,
                parking);

            await context.SaveChangesAsync(ct);

            var admin = new User
            {
                FirstName = "Desktop",
                LastName = "Admin",
                Username = "desktop",
                Email = "desktop@meetspace.ba",
                PasswordHash = passwordHasher.Hash("test"),
                PhoneNumber = "+387 61 100 100",
                RoleId = 1,
                IsActive = true
            };

            var mobileUser = new User
            {
                FirstName = "Mobile",
                LastName = "User",
                Username = "mobile",
                Email = "mobile@meetspace.ba",
                PasswordHash = passwordHasher.Hash("test"),
                PhoneNumber = "+387 61 200 200",
                ProfileImageUrl = "https://meetspaceimages.blob.core.windows.net/user-images/user1.png",
                RoleId = 2,
                IsActive = true
            };

            context.Users.AddRange(admin, mobileUser);
            await context.SaveChangesAsync(ct);

            var mepasConferenceRoom = new Space
            {
                Name = "Mepas Conference Room",
                Description = "Elegant conference room suitable for business meetings, presentations and private corporate sessions.",
                PricePerHour = 35,
                Capacity = 30,
                FacilityId = mepasMall.Id,
                SpaceTypeId = conferenceRoom.Id
            };

            var coworkingHub = new Space
            {
                Name = "Coworking Hub",
                Description = "Open coworking space designed for freelancers, remote teams and small workshops.",
                PricePerHour = 12,
                Capacity = 20,
                FacilityId = intera.Id,
                SpaceTypeId = coworkingSpace.Id
            };

            var interaILab = new Space
            {
                Name = "Intera iLab",
                Description = "Creative lab space equipped for prototyping, brainstorming and hands-on innovation sessions.",
                PricePerHour = 18,
                Capacity = 15,
                FacilityId = intera.Id,
                SpaceTypeId = lab.Id
            };

            var interaConferenceRoom = new Space
            {
                Name = "Intera Conference Room",
                Description = "Professional conference room for team meetings, trainings and partner presentations.",
                PricePerHour = 25,
                Capacity = 28,
                FacilityId = intera.Id,
                SpaceTypeId = conferenceRoom.Id
            };

            var interaItClassroom = new Space
            {
                Name = "Intera IT Classroom",
                Description = "Classroom configured for IT trainings, lectures and educational workshops.",
                PricePerHour = 22,
                Capacity = 24,
                FacilityId = intera.Id,
                SpaceTypeId = classroom.Id
            };

            var oldTownNest = new Space
            {
                Name = "Old Town Nest",
                Description = "Quiet private office near the Old Town, ideal for focused work and small client meetings.",
                PricePerHour = 16,
                Capacity = 6,
                FacilityId = oldTown.Id,
                SpaceTypeId = privateOffice.Id
            };

            context.Spaces.AddRange(
                mepasConferenceRoom,
                coworkingHub,
                interaILab,
                interaConferenceRoom,
                interaItClassroom,
                oldTownNest);

            await context.SaveChangesAsync(ct);

            context.SpaceImages.AddRange(
                new SpaceImage
                {
                    SpaceId = mepasConferenceRoom.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/mepas1.png"
                },
                new SpaceImage
                {
                    SpaceId = mepasConferenceRoom.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/mepas2.png"
                },
                new SpaceImage
                {
                    SpaceId = mepasConferenceRoom.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/mepas3.png"
                },

                new SpaceImage
                {
                    SpaceId = coworkingHub.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/coworkinghub1.png"
                },
                new SpaceImage
                {
                    SpaceId = coworkingHub.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/coworkinghub2.png"
                },
                new SpaceImage
                {
                    SpaceId = coworkingHub.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/coworkinghub3.png"
                },

                new SpaceImage
                {
                    SpaceId = interaILab.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/fablab1.png"
                },
                new SpaceImage
                {
                    SpaceId = interaILab.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/fablab2.png"
                },

                new SpaceImage
                {
                    SpaceId = interaConferenceRoom.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/interaconferenceroom1.png"
                },
                new SpaceImage
                {
                    SpaceId = interaConferenceRoom.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/interaconferenceroom2.png"
                },
                new SpaceImage
                {
                    SpaceId = interaConferenceRoom.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/interaconferenceroom3.png"
                },

                new SpaceImage
                {
                    SpaceId = interaItClassroom.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/itclassroom1.png"
                },
                new SpaceImage
                {
                    SpaceId = interaItClassroom.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/itclassroom2.png"
                },
                new SpaceImage
                {
                    SpaceId = interaItClassroom.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/itclassroom3.png"
                },

                new SpaceImage
                {
                    SpaceId = oldTownNest.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/oldtownnest1.png"
                },
                new SpaceImage
                {
                    SpaceId = oldTownNest.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/oldtownnest2.png"
                },
                new SpaceImage
                {
                    SpaceId = oldTownNest.Id,
                    ImageUrl = "https://meetspaceimages.blob.core.windows.net/space-images/oldtownnest3.png"
                }
            );

            context.SpaceAmenities.AddRange(
                new SpaceAmenity
                {
                    SpaceId = mepasConferenceRoom.Id,
                    AmenityId = projector.Id
                },
                new SpaceAmenity
                {
                    SpaceId = mepasConferenceRoom.Id,
                    AmenityId = whiteboard.Id
                },
                new SpaceAmenity
                {
                    SpaceId = mepasConferenceRoom.Id,
                    AmenityId = soundSystem.Id
                },
                new SpaceAmenity
                {
                    SpaceId = mepasConferenceRoom.Id,
                    AmenityId = coffee.Id
                },

                new SpaceAmenity
                {
                    SpaceId = coworkingHub.Id,
                    AmenityId = coffee.Id
                },
                new SpaceAmenity
                {
                    SpaceId = coworkingHub.Id,
                    AmenityId = parking.Id
                },
                new SpaceAmenity
                {
                    SpaceId = coworkingHub.Id,
                    AmenityId = whiteboard.Id
                },

                new SpaceAmenity
                {
                    SpaceId = interaILab.Id,
                    AmenityId = technicalSupport.Id
                },
                new SpaceAmenity
                {
                    SpaceId = interaILab.Id,
                    AmenityId = projector.Id
                },
                new SpaceAmenity
                {
                    SpaceId = interaILab.Id,
                    AmenityId = whiteboard.Id
                },

                new SpaceAmenity
                {
                    SpaceId = interaConferenceRoom.Id,
                    AmenityId = projector.Id
                },
                new SpaceAmenity
                {
                    SpaceId = interaConferenceRoom.Id,
                    AmenityId = soundSystem.Id
                },
                new SpaceAmenity
                {
                    SpaceId = interaConferenceRoom.Id,
                    AmenityId = catering.Id
                },

                new SpaceAmenity
                {
                    SpaceId = interaItClassroom.Id,
                    AmenityId = projector.Id
                },
                new SpaceAmenity
                {
                    SpaceId = interaItClassroom.Id,
                    AmenityId = whiteboard.Id
                },
                new SpaceAmenity
                {
                    SpaceId = interaItClassroom.Id,
                    AmenityId = technicalSupport.Id
                },

                new SpaceAmenity
                {
                    SpaceId = oldTownNest.Id,
                    AmenityId = coffee.Id
                },
                new SpaceAmenity
                {
                    SpaceId = oldTownNest.Id,
                    AmenityId = parking.Id
                }
            );

            await context.SaveChangesAsync(ct);

            var user2 = new User
            {
                FirstName = "User",
                LastName = "Two",
                Username = "user2",
                Email = "user2@meetspace.ba",
                PasswordHash = passwordHasher.Hash("test"),
                PhoneNumber = "+387 61 300 300",
                RoleId = 2,
                IsActive = true
            };

            var user3 = new User
            {
                FirstName = "User",
                LastName = "Three",
                Username = "user3",
                Email = "user3@meetspace.ba",
                PasswordHash = passwordHasher.Hash("test"),
                PhoneNumber = "+387 61 400 400",
                RoleId = 2,
                IsActive = true
            };

            context.Users.AddRange(user2, user3);
            await context.SaveChangesAsync(ct);

            var now = DateTime.UtcNow;

            var mobileMepasBooking = new Booking
            {
                UserId = mobileUser.Id,
                SpaceId = mepasConferenceRoom.Id,
                BookingStatusId = (int)BookingStatusEnum.Approved,
                PaymentStatusId = (int)PaymentStatusEnum.Completed,
                StartTime = now.AddDays(-35).Date.AddHours(10),
                EndTime = now.AddDays(-35).Date.AddHours(12),
                TotalPrice = 70,
                CreatedAt = now.AddDays(-36),
                UpdatedAt = now.AddDays(-35)
            };

            var mobileCoworkingBooking = new Booking
            {
                UserId = mobileUser.Id,
                SpaceId = coworkingHub.Id,
                BookingStatusId = (int)BookingStatusEnum.Approved,
                PaymentStatusId = (int)PaymentStatusEnum.Completed,
                StartTime = now.AddDays(-20).Date.AddHours(9),
                EndTime = now.AddDays(-20).Date.AddHours(12),
                TotalPrice = 36,
                CreatedAt = now.AddDays(-21),
                UpdatedAt = now.AddDays(-20)
            };

            var user2CoworkingBooking = new Booking
            {
                UserId = user2.Id,
                SpaceId = coworkingHub.Id,
                BookingStatusId = (int)BookingStatusEnum.Approved,
                PaymentStatusId = (int)PaymentStatusEnum.Completed,
                StartTime = now.AddDays(-30).Date.AddHours(13),
                EndTime = now.AddDays(-30).Date.AddHours(16),
                TotalPrice = 36,
                CreatedAt = now.AddDays(-31),
                UpdatedAt = now.AddDays(-30)
            };

            var user2InteraConferenceBooking = new Booking
            {
                UserId = user2.Id,
                SpaceId = interaConferenceRoom.Id,
                BookingStatusId = (int)BookingStatusEnum.Approved,
                PaymentStatusId = (int)PaymentStatusEnum.Completed,
                StartTime = now.AddDays(-18).Date.AddHours(11),
                EndTime = now.AddDays(-18).Date.AddHours(13),
                TotalPrice = 50,
                CreatedAt = now.AddDays(-19),
                UpdatedAt = now.AddDays(-18)
            };

            var user2ItClassroomBooking = new Booking
            {
                UserId = user2.Id,
                SpaceId = interaItClassroom.Id,
                BookingStatusId = (int)BookingStatusEnum.Approved,
                PaymentStatusId = (int)PaymentStatusEnum.Completed,
                StartTime = now.AddDays(-12).Date.AddHours(14),
                EndTime = now.AddDays(-12).Date.AddHours(16),
                TotalPrice = 44,
                CreatedAt = now.AddDays(-13),
                UpdatedAt = now.AddDays(-12)
            };

            var user3MepasBooking = new Booking
            {
                UserId = user3.Id,
                SpaceId = mepasConferenceRoom.Id,
                BookingStatusId = (int)BookingStatusEnum.Approved,
                PaymentStatusId = (int)PaymentStatusEnum.Completed,
                StartTime = now.AddDays(-28).Date.AddHours(15),
                EndTime = now.AddDays(-28).Date.AddHours(17),
                TotalPrice = 70,
                CreatedAt = now.AddDays(-29),
                UpdatedAt = now.AddDays(-28)
            };

            var user3InteraConferenceBooking = new Booking
            {
                UserId = user3.Id,
                SpaceId = interaConferenceRoom.Id,
                BookingStatusId = (int)BookingStatusEnum.Approved,
                PaymentStatusId = (int)PaymentStatusEnum.Completed,
                StartTime = now.AddDays(-15).Date.AddHours(10),
                EndTime = now.AddDays(-15).Date.AddHours(12),
                TotalPrice = 50,
                CreatedAt = now.AddDays(-16),
                UpdatedAt = now.AddDays(-15)
            };

            var user3OldTownBooking = new Booking
            {
                UserId = user3.Id,
                SpaceId = oldTownNest.Id,
                BookingStatusId = (int)BookingStatusEnum.Approved,
                PaymentStatusId = (int)PaymentStatusEnum.Completed,
                StartTime = now.AddDays(-8).Date.AddHours(9),
                EndTime = now.AddDays(-8).Date.AddHours(11),
                TotalPrice = 32,
                CreatedAt = now.AddDays(-9),
                UpdatedAt = now.AddDays(-8)
            };

            context.Bookings.AddRange(
                mobileMepasBooking,
                mobileCoworkingBooking,
                user2CoworkingBooking,
                user2InteraConferenceBooking,
                user2ItClassroomBooking,
                user3MepasBooking,
                user3InteraConferenceBooking,
                user3OldTownBooking
            );

            await context.SaveChangesAsync(ct);

            context.Payments.AddRange(
                new Payment
                {
                    BookingId = mobileMepasBooking.Id,
                    UserId = mobileUser.Id,
                    PaymentMethodId = (int)PaymentMethodEnum.Stripe,
                    PaymentStatusId = (int)PaymentStatusEnum.Completed,
                    Amount = mobileMepasBooking.TotalPrice,
                    PaymentDate = mobileMepasBooking.CreatedAt,
                    ExternalTransactionId = "seed-stripe-mobile-mepas"
                },
                new Payment
                {
                    BookingId = mobileCoworkingBooking.Id,
                    UserId = mobileUser.Id,
                    PaymentMethodId = (int)PaymentMethodEnum.PayPal,
                    PaymentStatusId = (int)PaymentStatusEnum.Completed,
                    Amount = mobileCoworkingBooking.TotalPrice,
                    PaymentDate = mobileCoworkingBooking.CreatedAt,
                    ExternalTransactionId = "seed-paypal-mobile-coworking"
                },
                new Payment
                {
                    BookingId = user2CoworkingBooking.Id,
                    UserId = user2.Id,
                    PaymentMethodId = (int)PaymentMethodEnum.Stripe,
                    PaymentStatusId = (int)PaymentStatusEnum.Completed,
                    Amount = user2CoworkingBooking.TotalPrice,
                    PaymentDate = user2CoworkingBooking.CreatedAt,
                    ExternalTransactionId = "seed-stripe-user2-coworking"
                },
                new Payment
                {
                    BookingId = user2InteraConferenceBooking.Id,
                    UserId = user2.Id,
                    PaymentMethodId = (int)PaymentMethodEnum.PayPal,
                    PaymentStatusId = (int)PaymentStatusEnum.Completed,
                    Amount = user2InteraConferenceBooking.TotalPrice,
                    PaymentDate = user2InteraConferenceBooking.CreatedAt,
                    ExternalTransactionId = "seed-paypal-user2-conference"
                },
                new Payment
                {
                    BookingId = user2ItClassroomBooking.Id,
                    UserId = user2.Id,
                    PaymentMethodId = (int)PaymentMethodEnum.Stripe,
                    PaymentStatusId = (int)PaymentStatusEnum.Completed,
                    Amount = user2ItClassroomBooking.TotalPrice,
                    PaymentDate = user2ItClassroomBooking.CreatedAt,
                    ExternalTransactionId = "seed-stripe-user2-classroom"
                },
                new Payment
                {
                    BookingId = user3MepasBooking.Id,
                    UserId = user3.Id,
                    PaymentMethodId = (int)PaymentMethodEnum.PayPal,
                    PaymentStatusId = (int)PaymentStatusEnum.Completed,
                    Amount = user3MepasBooking.TotalPrice,
                    PaymentDate = user3MepasBooking.CreatedAt,
                    ExternalTransactionId = "seed-paypal-user3-mepas"
                },
                new Payment
                {
                    BookingId = user3InteraConferenceBooking.Id,
                    UserId = user3.Id,
                    PaymentMethodId = (int)PaymentMethodEnum.Stripe,
                    PaymentStatusId = (int)PaymentStatusEnum.Completed,
                    Amount = user3InteraConferenceBooking.TotalPrice,
                    PaymentDate = user3InteraConferenceBooking.CreatedAt,
                    ExternalTransactionId = "seed-stripe-user3-conference"
                },
                new Payment
                {
                    BookingId = user3OldTownBooking.Id,
                    UserId = user3.Id,
                    PaymentMethodId = (int)PaymentMethodEnum.PayPal,
                    PaymentStatusId = (int)PaymentStatusEnum.Completed,
                    Amount = user3OldTownBooking.TotalPrice,
                    PaymentDate = user3OldTownBooking.CreatedAt,
                    ExternalTransactionId = "seed-paypal-user3-oldtown"
                }
            );

            context.Reviews.AddRange(
                new Review
                {
                    UserId = mobileUser.Id,
                    SpaceId = mepasConferenceRoom.Id,
                    Rating = 5,
                    Comment = "Great room for a focused business meeting.",
                    CreatedAt = now.AddDays(-34)
                },
                new Review
                {
                    UserId = mobileUser.Id,
                    SpaceId = coworkingHub.Id,
                    Rating = 4,
                    Comment = "Comfortable coworking space with a productive atmosphere.",
                    CreatedAt = now.AddDays(-19)
                },
                new Review
                {
                    UserId = user2.Id,
                    SpaceId = coworkingHub.Id,
                    Rating = 5,
                    Comment = "Excellent place for team work and short workshops.",
                    CreatedAt = now.AddDays(-29)
                },
                new Review
                {
                    UserId = user2.Id,
                    SpaceId = interaConferenceRoom.Id,
                    Rating = 5,
                    Comment = "Professional setup and very good equipment.",
                    CreatedAt = now.AddDays(-17)
                },
                new Review
                {
                    UserId = user3.Id,
                    SpaceId = oldTownNest.Id,
                    Rating = 4,
                    Comment = "Quiet and practical office for focused work.",
                    CreatedAt = now.AddDays(-7)
                }
            );

            context.Favorites.AddRange(
                new Favorite
                {
                    UserId = mobileUser.Id,
                    SpaceId = interaConferenceRoom.Id
                },
                new Favorite
                {
                    UserId = mobileUser.Id,
                    SpaceId = interaItClassroom.Id
                },
                new Favorite
                {
                    UserId = user2.Id,
                    SpaceId = coworkingHub.Id
                },
                new Favorite
                {
                    UserId = user3.Id,
                    SpaceId = mepasConferenceRoom.Id
                }
            );

            context.BookingAuditLogs.AddRange(
                new BookingAuditLog
                {
                    BookingId = mobileMepasBooking.Id,
                    AdminId = admin.Id,
                    Action = "Approved",
                    Comment = "Seed demo approval.",
                    CreatedAt = mobileMepasBooking.UpdatedAt ?? now.AddDays(-35)
                },
                new BookingAuditLog
                {
                    BookingId = mobileCoworkingBooking.Id,
                    AdminId = admin.Id,
                    Action = "Approved",
                    Comment = "Seed demo approval.",
                    CreatedAt = mobileCoworkingBooking.UpdatedAt ?? now.AddDays(-20)
                },
                new BookingAuditLog
                {
                    BookingId = user2CoworkingBooking.Id,
                    AdminId = admin.Id,
                    Action = "Approved",
                    Comment = "Seed demo approval.",
                    CreatedAt = user2CoworkingBooking.UpdatedAt ?? now.AddDays(-30)
                },
                new BookingAuditLog
                {
                    BookingId = user2InteraConferenceBooking.Id,
                    AdminId = admin.Id,
                    Action = "Approved",
                    Comment = "Seed demo approval.",
                    CreatedAt = user2InteraConferenceBooking.UpdatedAt ?? now.AddDays(-18)
                },
                new BookingAuditLog
                {
                    BookingId = user2ItClassroomBooking.Id,
                    AdminId = admin.Id,
                    Action = "Approved",
                    Comment = "Seed demo approval.",
                    CreatedAt = user2ItClassroomBooking.UpdatedAt ?? now.AddDays(-12)
                },
                new BookingAuditLog
                {
                    BookingId = user3MepasBooking.Id,
                    AdminId = admin.Id,
                    Action = "Approved",
                    Comment = "Seed demo approval.",
                    CreatedAt = user3MepasBooking.UpdatedAt ?? now.AddDays(-28)
                },
                new BookingAuditLog
                {
                    BookingId = user3InteraConferenceBooking.Id,
                    AdminId = admin.Id,
                    Action = "Approved",
                    Comment = "Seed demo approval.",
                    CreatedAt = user3InteraConferenceBooking.UpdatedAt ?? now.AddDays(-15)
                },
                new BookingAuditLog
                {
                    BookingId = user3OldTownBooking.Id,
                    AdminId = admin.Id,
                    Action = "Approved",
                    Comment = "Seed demo approval.",
                    CreatedAt = user3OldTownBooking.UpdatedAt ?? now.AddDays(-8)
                }
            );

            await context.SaveChangesAsync(ct);

            var mobileFutureMepasBooking = new Booking
            {
                UserId = mobileUser.Id,
                SpaceId = mepasConferenceRoom.Id,
                BookingStatusId = (int)BookingStatusEnum.Pending,
                PaymentStatusId = (int)PaymentStatusEnum.Completed,
                StartTime = now.AddDays(30).Date.AddHours(10),
                EndTime = now.AddDays(30).Date.AddHours(12),
                TotalPrice = 70,
                CreatedAt = now.AddDays(-2),
                UpdatedAt = now.AddDays(-2)
            };

            var mobileFutureInteraConferenceBooking = new Booking
            {
                UserId = mobileUser.Id,
                SpaceId = interaConferenceRoom.Id,
                BookingStatusId = (int)BookingStatusEnum.Pending,
                PaymentStatusId = (int)PaymentStatusEnum.Completed,
                StartTime = now.AddDays(37).Date.AddHours(14),
                EndTime = now.AddDays(37).Date.AddHours(16),
                TotalPrice = 50,
                CreatedAt = now.AddDays(-1),
                UpdatedAt = now.AddDays(-1)
            };

            var mobileFutureOldTownBooking = new Booking
            {
                UserId = mobileUser.Id,
                SpaceId = oldTownNest.Id,
                BookingStatusId = (int)BookingStatusEnum.Pending,
                PaymentStatusId = (int)PaymentStatusEnum.Completed,
                StartTime = now.AddDays(45).Date.AddHours(9),
                EndTime = now.AddDays(45).Date.AddHours(11),
                TotalPrice = 32,
                CreatedAt = now,
                UpdatedAt = now
            };

            context.Bookings.AddRange(
                mobileFutureMepasBooking,
                mobileFutureInteraConferenceBooking,
                mobileFutureOldTownBooking
            );

            await context.SaveChangesAsync(ct);

            context.Payments.AddRange(
                new Payment
                {
                    BookingId = mobileFutureMepasBooking.Id,
                    UserId = mobileUser.Id,
                    PaymentMethodId = (int)PaymentMethodEnum.Stripe,
                    PaymentStatusId = (int)PaymentStatusEnum.Completed,
                    Amount = mobileFutureMepasBooking.TotalPrice,
                    PaymentDate = mobileFutureMepasBooking.CreatedAt,
                    ExternalTransactionId = "seed-stripe-mobile-future-mepas"
                },
                new Payment
                {
                    BookingId = mobileFutureInteraConferenceBooking.Id,
                    UserId = mobileUser.Id,
                    PaymentMethodId = (int)PaymentMethodEnum.PayPal,
                    PaymentStatusId = (int)PaymentStatusEnum.Completed,
                    Amount = mobileFutureInteraConferenceBooking.TotalPrice,
                    PaymentDate = mobileFutureInteraConferenceBooking.CreatedAt,
                    ExternalTransactionId = "seed-paypal-mobile-future-conference"
                },
                new Payment
                {
                    BookingId = mobileFutureOldTownBooking.Id,
                    UserId = mobileUser.Id,
                    PaymentMethodId = (int)PaymentMethodEnum.Stripe,
                    PaymentStatusId = (int)PaymentStatusEnum.Completed,
                    Amount = mobileFutureOldTownBooking.TotalPrice,
                    PaymentDate = mobileFutureOldTownBooking.CreatedAt,
                    ExternalTransactionId = "seed-stripe-mobile-future-oldtown"
                }
            );

            await context.SaveChangesAsync(ct);
        }

        private static async Task InsertWithIdentityAsync(
      MeetSpaceDbContext context,
      string tableName,
      Func<Task> insertAction)
        {
            await context.Database.OpenConnectionAsync();

            try
            {
                await context.Database.ExecuteSqlRawAsync($"SET IDENTITY_INSERT {tableName} ON");

                try
                {
                    await insertAction();
                }
                finally
                {
                    await context.Database.ExecuteSqlRawAsync($"SET IDENTITY_INSERT {tableName} OFF");
                }
            }
            finally
            {
                await context.Database.CloseConnectionAsync();
            }
        }
    }
}