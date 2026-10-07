import 'package:flutter/material.dart';
import '../services/favourite_service.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    await FavouriteService.loadFavourites();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavourite(int index) async {
    await FavouriteService.removeFavourite(index);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Favourite passage removed ❤️',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favourites = FavouriteService.favourites;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FC),
      appBar: AppBar(
        title: const Text(
          'My Favourites ❤️',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B5B7B),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC8B6E2),
        ),
      )
          : favourites.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.format_quote_rounded,
                size: 80,
                color: Color(0xFFC8B6E2),
              ),
              SizedBox(height: 20),
              Text(
                'No Favourite Passages Yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B5B7B),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Save quotes, lines and dialogues while reading '
                    'and they will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF9A8FA3),
                ),
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: favourites.length,
        itemBuilder: (context, index) {
          final favourite = favourites[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8DDF1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    favourite['type'] ?? 'Quote',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B5B7B),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  '“${favourite['content'] ?? ''}”',
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF5E5368),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  '— ${favourite['title'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B5B7B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${favourite['author'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9A8FA3),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.pink,
                    ),
                    onPressed: () {
                      _removeFavourite(index);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}