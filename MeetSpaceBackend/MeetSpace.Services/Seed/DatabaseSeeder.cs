using MeetSpace.Models.Constants;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Enums;
using MeetSpace.Services.Database;
using MeetSpace.Services.Security;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

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
            {
                await SyncOperationalCatalogAsync(context, ct);
                return;
            }

            await SeedFixedDataAsync(context, ct);
            await SeedReferenceDataAsync(context, passwordHasher, ct);
            await SyncOperationalCatalogAsync(context, ct);
        }

        private static async Task SyncOperationalCatalogAsync(
            MeetSpaceDbContext context,
            CancellationToken ct)
        {
            var catalogPath = Path.Combine(AppContext.BaseDirectory, "Seed", "operational_catalog.json");
            if (!File.Exists(catalogPath))
                throw new FileNotFoundException("Operational space catalog file was not found.", catalogPath);

            var catalog = JsonSerializer.Deserialize<List<OperationalCatalogEntry>>(
                await File.ReadAllTextAsync(catalogPath, ct),
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true })
                ?? throw new InvalidDataException("Operational space catalog is empty or invalid.");

            if (catalog.Count != 37 || catalog.Select(x => x.SpaceCode).Distinct().Count() != catalog.Count)
                throw new InvalidDataException("Operational catalog must contain 37 unique space codes.");

            await using var transaction = await context.Database.BeginTransactionAsync(ct);

            var country = await context.Countries.FirstOrDefaultAsync(
                x => x.Name == "Bosna i Hercegovina" || x.Name == "Bosnia and Herzegovina", ct);
            if (country == null)
            {
                country = new Country { Name = "Bosna i Hercegovina" };
                context.Countries.Add(country);
                await context.SaveChangesAsync(ct);
            }

            var cityNames = catalog.Select(x => x.CityName).Distinct().ToList();
            var cities = await context.Cities.ToListAsync(ct);
            foreach (var name in cityNames)
            {
                var city = cities.FirstOrDefault(x => x.Name.Equals(name, StringComparison.OrdinalIgnoreCase));
                if (city == null)
                {
                    city = new City { Name = name, CountryId = country.Id };
                    context.Cities.Add(city);
                    cities.Add(city);
                }
                else
                {
                    city.Name = name;
                    city.CountryId = country.Id;
                }
            }
            await context.SaveChangesAsync(ct);

            var legacyFacilityAliases = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["Hotel Mepas"] = "Mepas Mall",
                ["INTERA Tehnološki Park"] = "Intera Technology Park",
                ["Old Town Nest"] = "Old Town Workspace"
            };
            var facilities = await context.Facilities.ToListAsync(ct);
            foreach (var row in catalog.GroupBy(x => x.FacilityName).Select(x => x.First()))
            {
                var facility = facilities.FirstOrDefault(x =>
                    x.Name.Equals(row.FacilityName, StringComparison.OrdinalIgnoreCase));
                if (facility == null && legacyFacilityAliases.TryGetValue(row.FacilityName, out var legacyName))
                    facility = facilities.FirstOrDefault(x => x.Name.Equals(legacyName, StringComparison.OrdinalIgnoreCase));

                var city = cities.First(x => x.Name.Equals(row.CityName, StringComparison.OrdinalIgnoreCase));
                if (facility == null)
                {
                    facility = new Facility { Name = row.FacilityName, Address = row.Address, CityId = city.Id };
                    context.Facilities.Add(facility);
                    facilities.Add(facility);
                }
                else
                {
                    facility.Name = row.FacilityName;
                    facility.Address = row.Address;
                    facility.CityId = city.Id;
                    facility.Description = null;
                    facility.ContactEmail = null;
                    facility.ContactPhone = null;
                }
            }
            await context.SaveChangesAsync(ct);

            var types = await context.SpaceTypes.ToListAsync(ct);
            var typeAliases = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["Radni prostor"] = "Coworking Space",
                ["Prostor za sastanke"] = "Conference Room",
                ["Prostor za edukacije"] = "Classroom",
                ["Prostor za poslovne događaje"] = "Lab"
            };
            var typeIds = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            foreach (var name in catalog.Select(x => x.SpaceTypeName).Distinct())
            {
                var type = types.FirstOrDefault(x => x.Name.Equals(name, StringComparison.OrdinalIgnoreCase));
                if (type == null && typeAliases.TryGetValue(name, out var alias))
                {
                    type = types.FirstOrDefault(x => x.Name.Equals(alias, StringComparison.OrdinalIgnoreCase));
                    if (type != null) type.Name = name;
                }
                if (type == null)
                {
                    type = new SpaceType { Name = name };
                    context.SpaceTypes.Add(type);
                    types.Add(type);
                }
                typeIds[name] = type.Id;
            }
            await context.SaveChangesAsync(ct);
            foreach (var type in types.Where(x => typeIds.ContainsKey(x.Name)))
                typeIds[type.Name] = type.Id;

            var workTypeId = typeIds["Radni prostor"];
            var legacyPrivateOffice = types.FirstOrDefault(x => x.Name.Equals("Private Office", StringComparison.OrdinalIgnoreCase));
            if (legacyPrivateOffice != null)
            {
                await context.Spaces.Where(x => x.SpaceTypeId == legacyPrivateOffice.Id)
                    .ExecuteUpdateAsync(update => update.SetProperty(x => x.SpaceTypeId, workTypeId), ct);
                context.SpaceTypes.Remove(legacyPrivateOffice);
                await context.SaveChangesAsync(ct);
            }

            var facilitiesByName = facilities.ToDictionary(x => x.Name, StringComparer.OrdinalIgnoreCase);
            var spaces = await context.Spaces.ToListAsync(ct);
            var spaceByCode = spaces.Where(x => x.SpaceCode != null)
                .ToDictionary(x => x.SpaceCode!, StringComparer.OrdinalIgnoreCase);

            var now = DateTime.UtcNow;
            foreach (var legacy in spaces.Where(x => x.SpaceCode == null && x.IsActive))
            {
                legacy.IsActive = false;
                legacy.ArchivedAt ??= now;
            }

            foreach (var row in catalog)
            {
                if (!facilitiesByName.TryGetValue(row.FacilityName, out var facility))
                    throw new InvalidDataException($"Facility '{row.FacilityName}' is missing from the catalog.");

                if (!typeIds.TryGetValue(row.SpaceTypeName, out var typeId))
                    throw new InvalidDataException($"Space type '{row.SpaceTypeName}' is missing from the catalog.");

                if (!spaceByCode.TryGetValue(row.SpaceCode, out var space))
                {
                    space = new Space { SpaceCode = row.SpaceCode, CreatedAt = now };
                    context.Spaces.Add(space);
                    spaceByCode.Add(row.SpaceCode, space);
                    spaces.Add(space);
                }

                space.Name = row.SpaceName;
                space.Description = BuildOperationalSpaceDescription(row.SpaceName, row.SpaceTypeName);
                space.PricePerHour = row.PricePerHour;
                space.PriceBasis = row.PriceBasis;
                space.PriceSource = row.PriceSource;
                space.PriceNotes = row.PriceNotes;
                space.Capacity = row.Capacity;
                space.FacilityId = facility.Id;
                space.SpaceTypeId = typeId;
                space.IsActive = true;
                space.ArchivedAt = null;
                space.UpdatedAt = now;
            }

            await context.SaveChangesAsync(ct);
            await SeedOperationalSpaceDetailsAsync(
                context,
                spaces.Where(x => x.SpaceCode != null && x.IsActive).ToList(),
                ct);
            await transaction.CommitAsync(ct);
        }

        private static string BuildOperationalSpaceDescription(string name, string typeName) => typeName switch
        {
            "Radni prostor" => $"{name} is a comfortable workspace for focused work, independent professionals and everyday productivity.",
            "Prostor za sastanke" => $"{name} is a private meeting space suited to team discussions, client meetings and focused collaboration.",
            "Prostor za edukacije" => $"{name} is arranged for training sessions, workshops and collaborative learning.",
            "Prostor za poslovne događaje" => $"{name} is a flexible venue for presentations, workshops and business gatherings.",
            _ => $"{name} is a welcoming space for work and collaboration."
        };

        private static async Task SeedOperationalSpaceDetailsAsync(
            MeetSpaceDbContext context,
            List<Space> spaces,
            CancellationToken ct)
        {
            var categoryNames = new[] { "Equipment", "Food and Drinks", "Services" };
            var categories = await context.AmenityCategories.ToListAsync(ct);
            foreach (var name in categoryNames)
            {
                if (categories.Any(x => x.Name.Equals(name, StringComparison.OrdinalIgnoreCase)))
                    continue;

                var category = new AmenityCategory { Name = name };
                context.AmenityCategories.Add(category);
                categories.Add(category);
            }
            await context.SaveChangesAsync(ct);

            var categoryIds = categories.ToDictionary(x => x.Name, x => x.Id, StringComparer.OrdinalIgnoreCase);
            var amenitySpecs = new[]
            {
                (Name: "Projector", Description: "HD projector for presentations and workshops.", Price: 10m, Category: "Equipment"),
                (Name: "Whiteboard", Description: "Whiteboard with markers.", Price: 5m, Category: "Equipment"),
                (Name: "Sound System", Description: "Audio setup for meetings and events.", Price: 20m, Category: "Equipment"),
                (Name: "Coffee", Description: "Coffee service for participants.", Price: 3m, Category: "Food and Drinks"),
                (Name: "Catering", Description: "Light catering for meetings and events.", Price: 15m, Category: "Food and Drinks"),
                (Name: "Technical Support", Description: "On-site technical assistance.", Price: 25m, Category: "Services"),
                (Name: "Parking", Description: "Reserved parking space.", Price: 5m, Category: "Services")
            };
            var amenities = await context.Amenities.ToListAsync(ct);
            foreach (var spec in amenitySpecs)
            {
                if (amenities.Any(x => x.Name.Equals(spec.Name, StringComparison.OrdinalIgnoreCase)))
                    continue;

                var amenity = new Amenity
                {
                    Name = spec.Name,
                    Description = spec.Description,
                    Price = spec.Price,
                    AmenityCategoryId = categoryIds[spec.Category]
                };
                context.Amenities.Add(amenity);
                amenities.Add(amenity);
            }
            await context.SaveChangesAsync(ct);

            var amenityIds = amenities.ToDictionary(x => x.Name, x => x.Id, StringComparer.OrdinalIgnoreCase);
            var spaceIds = spaces.Select(x => x.Id).ToList();
            var existingLinks = await context.SpaceAmenities
                .Where(x => spaceIds.Contains(x.SpaceId))
                .ToListAsync(ct);
            var spaceTypeNames = await context.SpaceTypes.ToDictionaryAsync(x => x.Id, x => x.Name, ct);

            var workImages = new[]
            {
                "https://meetspaceimages.blob.core.windows.net/space-images/coworkinghub1.png",
                "https://meetspaceimages.blob.core.windows.net/space-images/coworkinghub2.png",
                "https://meetspaceimages.blob.core.windows.net/space-images/coworkinghub3.png",
                "https://meetspaceimages.blob.core.windows.net/space-images/oldtownnest1.png"
            };
            var meetingImages = new[]
            {
                "https://meetspaceimages.blob.core.windows.net/space-images/mepas1.png",
                "https://meetspaceimages.blob.core.windows.net/space-images/interaconferenceroom1.png",
                "https://meetspaceimages.blob.core.windows.net/space-images/interaconferenceroom2.png"
            };
            var educationImages = new[]
            {
                "https://meetspaceimages.blob.core.windows.net/space-images/itclassroom1.png",
                "https://meetspaceimages.blob.core.windows.net/space-images/itclassroom2.png",
                "https://meetspaceimages.blob.core.windows.net/space-images/itclassroom3.png"
            };
            var eventImages = new[]
            {
                "https://meetspaceimages.blob.core.windows.net/space-images/fablab1.png",
                "https://meetspaceimages.blob.core.windows.net/space-images/fablab2.png",
                "https://meetspaceimages.blob.core.windows.net/space-images/mepas2.png"
            };

            var clients = await context.Users
                .Where(x => x.IsActive && x.RoleId != 1)
                .OrderBy(x => x.Id)
                .ToListAsync(ct);
            var existingReviewSpaceIds = await context.Reviews
                .Where(x => spaceIds.Contains(x.SpaceId))
                .Select(x => x.SpaceId)
                .Distinct()
                .ToListAsync(ct);
            var reviewComments = new[]
            {
                "Comfortable, well arranged and a good fit for the session.",
                "A pleasant space with everything needed for a productive visit.",
                "Convenient location and a welcoming setup for the whole group.",
                "The space was clean, practical and easy to use."
            };

            for (var index = 0; index < spaces.Count; index++)
            {
                var space = spaces[index];
                var typeName = spaceTypeNames[space.SpaceTypeId];
                var targetAmenities = typeName switch
                {
                    "Radni prostor" => new[] { "Coffee", "Parking" },
                    "Prostor za sastanke" => new[] { "Projector", "Whiteboard", "Coffee" },
                    "Prostor za edukacije" => new[] { "Projector", "Whiteboard", "Technical Support" },
                    _ => new[] { "Sound System", "Catering", "Technical Support" }
                };

                if (!existingLinks.Any(x => x.SpaceId == space.Id))
                {
                    foreach (var amenityName in targetAmenities)
                    {
                        context.SpaceAmenities.Add(new SpaceAmenity
                        {
                            SpaceId = space.Id,
                            AmenityId = amenityIds[amenityName]
                        });
                    }
                }

                var imageUrls = typeName switch
                {
                    "Radni prostor" => workImages,
                    "Prostor za sastanke" => meetingImages,
                    "Prostor za edukacije" => educationImages,
                    _ => eventImages
                };
                var existingImageCount = await context.SpaceImages.CountAsync(x => x.SpaceId == space.Id, ct);
                if (existingImageCount == 0)
                {
                    context.SpaceImages.Add(new SpaceImage
                    {
                        SpaceId = space.Id,
                        ImageUrl = imageUrls[index % imageUrls.Length]
                    });
                }

                if (!existingReviewSpaceIds.Contains(space.Id) && clients.Count > 0)
                {
                    context.Reviews.Add(new Review
                    {
                        UserId = clients[index % clients.Count].Id,
                        SpaceId = space.Id,
                        Rating = index % 4 == 0 ? 4 : 5,
                        Comment = reviewComments[index % reviewComments.Length],
                        CreatedAt = DateTime.UtcNow.AddDays(-index - 1)
                    });
                }
            }

            await context.SaveChangesAsync(ct);
        }

        private sealed class OperationalCatalogEntry
        {
            public string SpaceCode { get; set; } = string.Empty;
            public string SpaceName { get; set; } = string.Empty;
            public string SpaceTypeName { get; set; } = string.Empty;
            public string FacilityName { get; set; } = string.Empty;
            public string Address { get; set; } = string.Empty;
            public string CityName { get; set; } = string.Empty;
            public int Capacity { get; set; }
            public decimal PricePerHour { get; set; }
            public string PriceBasis { get; set; } = "Simulated";
            public string? PriceSource { get; set; }
            public string? PriceNotes { get; set; }
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
                SpaceTypeId = conferenceRoom.Id,
                IsActive = true
            };

            var coworkingHub = new Space
            {
                Name = "Coworking Hub",
                Description = "Open coworking space designed for freelancers, remote teams and small workshops.",
                PricePerHour = 12,
                Capacity = 20,
                FacilityId = intera.Id,
                SpaceTypeId = coworkingSpace.Id,
                IsActive = true
            };

            var interaILab = new Space
            {
                Name = "Intera iLab",
                Description = "Creative lab space equipped for prototyping, brainstorming and hands-on innovation sessions.",
                PricePerHour = 18,
                Capacity = 15,
                FacilityId = intera.Id,
                SpaceTypeId = lab.Id,
                IsActive = true
            };

            var interaConferenceRoom = new Space
            {
                Name = "Intera Conference Room",
                Description = "Professional conference room for team meetings, trainings and partner presentations.",
                PricePerHour = 25,
                Capacity = 28,
                FacilityId = intera.Id,
                SpaceTypeId = conferenceRoom.Id,
                IsActive = true
            };

            var interaItClassroom = new Space
            {
                Name = "Intera IT Classroom",
                Description = "Classroom configured for IT trainings, lectures and educational workshops.",
                PricePerHour = 22,
                Capacity = 24,
                FacilityId = intera.Id,
                SpaceTypeId = classroom.Id,
                IsActive = true
            };

            var oldTownNest = new Space
            {
                Name = "Old Town Nest",
                Description = "Quiet private office near the Old Town, ideal for focused work and small client meetings.",
                PricePerHour = 16,
                Capacity = 6,
                FacilityId = oldTown.Id,
                SpaceTypeId = privateOffice.Id,
                IsActive = true
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
