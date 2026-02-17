import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/space.dart';
import 'space_details_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  static const Color bgGrey = Color.fromARGB(255, 59, 59, 59);
  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

  Future<List<SpaceResponse>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadFavorites();
  }

  Future<List<SpaceResponse>> _loadFavorites() async {
    final auth = context.read<AuthProvider>();
    return auth.getFavoriteSpaces(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: bgGrey,
        elevation: 0,
        title: const Text(
          "Favorite Spaces",
          style: TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<List<SpaceResponse>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: brandOrange),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final spaces = snapshot.data ?? [];

          if (spaces.isEmpty) {
            return const Center(
              child: Text(
                "No favorites yet.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: spaces.length,
            itemBuilder: (context, index) {
              final s = spaces[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpaceDetailsPage(space: s),
                      ),
                    );
                  },
                  child: _FavoriteCard(space: s),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final SpaceResponse space;

  const _FavoriteCard({required this.space});

  @override
  Widget build(BuildContext context) {
    final imageUrl = space.firstImageOrEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: imageUrl.isEmpty
                ? const Center(child: Icon(Icons.image))
                : Image.network(imageUrl, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              space.name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }
}
