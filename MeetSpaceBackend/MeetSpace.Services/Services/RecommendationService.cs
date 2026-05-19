using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Enums;
using MeetSpace.Models.Responses;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Services.Services
{
    public class RecommendationService : IRecommendationService
    {
        private readonly MeetSpaceDbContext _context;
        private readonly IMapper _mapper;

        public RecommendationService(MeetSpaceDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<List<SpaceResponse>> GetRecommendedSpaces(int userId, int count = 5)
        {
            // 1️⃣ Učitaj interakcije
            var bookings = await _context.Bookings
    .Where(b => b.BookingStatusId == (int)BookingStatusEnum.Approved)
    .ToListAsync();
            var reviews = await _context.Reviews.ToListAsync();
            var favorites = await _context.Set<Favorite>().ToListAsync();

            // 2️⃣ Kreiraj user-item matricu
            var userItemScores = new Dictionary<int, Dictionary<int, double>>();

            void AddScore(int uId, int sId, double score)
            {
                if (!userItemScores.ContainsKey(uId))
                    userItemScores[uId] = new Dictionary<int, double>();

                if (!userItemScores[uId].ContainsKey(sId))
                    userItemScores[uId][sId] = 0;

                userItemScores[uId][sId] += score;
            }

            // Booking = 3
            foreach (var b in bookings)
                AddScore(b.UserId, b.SpaceId, 3);

            // Favorite = 2
            foreach (var f in favorites)
                AddScore(f.UserId, f.SpaceId, 2);

            // Review = rating
            foreach (var r in reviews)
                AddScore(r.UserId, r.SpaceId, r.Rating);

            // Ako user nema interakcije → fallback
            if (!userItemScores.ContainsKey(userId))
                return await GetTopRatedSpaces(count);

            var currentUserItems = userItemScores[userId];

            // 3️⃣ Izračun similarity između prostora
            var similarity = CalculateItemSimilarity(userItemScores);

            // 4️⃣ Izračun preporuke
            var scores = new Dictionary<int, double>();

            foreach (var item in currentUserItems)
            {
                int spaceId = item.Key;
                double rating = item.Value;

                if (!similarity.ContainsKey(spaceId))
                    continue;

                foreach (var sim in similarity[spaceId])
                {
                    if (currentUserItems.ContainsKey(sim.Key))
                        continue;

                    if (!scores.ContainsKey(sim.Key))
                        scores[sim.Key] = 0;

                    scores[sim.Key] += rating * sim.Value;
                }
            }

            if (!scores.Any())
                return await GetTopRatedSpaces(count);

            var recommendedIds = scores
                .OrderByDescending(x => x.Value)
                .Take(count)
                .Select(x => x.Key)
                .ToList();

            foreach (var spaceId in recommendedIds)
            {
                var alreadyLogged = await _context.RecommendationLogs
                    .AnyAsync(r => r.UserId == userId && r.SpaceId == spaceId && !r.Clicked && !r.Booked);

                if (!alreadyLogged)
                {
                    _context.RecommendationLogs.Add(new RecommendationLog
                    {
                        UserId = userId,
                        SpaceId = spaceId,
                        RecommendedAt = DateTime.UtcNow
                    });
                }
            }

            await _context.SaveChangesAsync();

            var spaces = await _context.Spaces
    .Where(s => recommendedIds.Contains(s.Id))
    .Include(s => s.Images)
    .Include(s => s.Facility)
    .ToListAsync();

            var ordered = spaces
                .OrderByDescending(s => scores.ContainsKey(s.Id) ? scores[s.Id] : 0)
                .ToList();

            var mapped = _mapper.Map<List<SpaceResponse>>(ordered);

            foreach (var space in mapped)
            {
                space.RecommendationReason =
                    "Recommended based on your previous bookings and similar user interactions.";
            }

            return mapped;

        }

        private Dictionary<int, Dictionary<int, double>> CalculateItemSimilarity(
            Dictionary<int, Dictionary<int, double>> userItemScores)
        {
            var similarity = new Dictionary<int, Dictionary<int, double>>();

            var allSpaces = userItemScores
                .SelectMany(u => u.Value.Keys)
                .Distinct()
                .ToList();

            foreach (var spaceA in allSpaces)
            {
                similarity[spaceA] = new Dictionary<int, double>();

                foreach (var spaceB in allSpaces)
                {
                    if (spaceA == spaceB) continue;

                    double dot = 0, normA = 0, normB = 0;

                    foreach (var user in userItemScores.Keys)
                    {
                        var userScores = userItemScores[user];

                        double scoreA = userScores.ContainsKey(spaceA) ? userScores[spaceA] : 0;
                        double scoreB = userScores.ContainsKey(spaceB) ? userScores[spaceB] : 0;

                        dot += scoreA * scoreB;
                        normA += scoreA * scoreA;
                        normB += scoreB * scoreB;
                    }

                    if (normA > 0 && normB > 0)
                    {
                        double sim = dot / (Math.Sqrt(normA) * Math.Sqrt(normB));
                        similarity[spaceA][spaceB] = sim;
                    }
                }
            }

            return similarity;
        }

        private async Task<List<SpaceResponse>> GetTopRatedSpaces(int count)
        {
            var spaces = await _context.Spaces
                .Include(s => s.Reviews)
                .Include(s => s.Images)
                .Include(s => s.Facility)
                .ToListAsync();

            var ordered = spaces
                .OrderByDescending(s => s.Reviews.Any() ? s.Reviews.Average(r => r.Rating) : 0)
                .Take(count)
                .ToList();

            var mapped = _mapper.Map<List<SpaceResponse>>(ordered);

            foreach (var space in mapped)
            {
                space.RecommendationReason =
                    "Popular highly-rated space.";
            }

            return mapped;
        }
    }
}
