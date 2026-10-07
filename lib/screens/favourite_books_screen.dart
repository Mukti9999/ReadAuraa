import 'package:flutter/material.dart';

import '../services/favourite_books_service.dart';
import 'book_details_screen.dart';

class FavouriteBooksScreen extends StatefulWidget {
  const FavouriteBooksScreen({super.key});

  @override
  State<FavouriteBooksScreen> createState() =>
      _FavouriteBooksScreenState();
}

class _FavouriteBooksScreenState
    extends State<FavouriteBooksScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavouriteBooks();
  }

  // LOCAL BOOK COVER MAPPING
  String _getCoverImage(String title) {
    final value = title.toLowerCase().trim();

    if (value.contains('hound of the baskervilles')) {
      return 'assets/covers/the_hound_of_the_baskervilles.jpg';
    }

    if (value.contains('adventure of sherlock holmes') ||
        value.contains('adventures of sherlock holmes')) {
      return 'assets/covers/the_adventure_of_sherlock_holmes.jpg';
    }

    if (value.contains('great gatsby')) {
      return 'assets/covers/the_great_gatsby.jpg';
    }

    if (value.contains('pride and prejudice') ||
        value.contains('pride & prejudice')) {
      return 'assets/covers/pride_and_prejudice.jpg';
    }

    if (value.contains('little women')) {
      return 'assets/covers/little_women.jpg';
    }

    if (value.contains('frankenstein')) {
      return 'assets/covers/frankenstein.jpg';
    }

    if (value.contains('dracula')) {
      return 'assets/covers/dracula.jpg';
    }

    if (value.contains('alice in wonderland') ||
        value.contains("alice's adventures in wonderland")) {
      return 'assets/covers/alice_in_wonderland.jpg';
    }

    return '';
  }

  Future<void> _loadFavouriteBooks() async {
    await FavouriteBooksService.loadFavouriteBooks();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _removeFavouriteBook(int index) async {
    await FavouriteBooksService.removeFavouriteBook(index);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Book removed from favourites ❤️',
          style: TextStyle(
            fontFamily: 'Times New Roman',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = FavouriteBooksService.favouriteBooks;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FC),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9FC),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Favourite Books ❤️',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B5B7B),
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC8B6E2),
        ),
      )
          : books.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 80,
                color: Color(0xFFC8B6E2),
              ),
              SizedBox(height: 20),
              Text(
                'No Favourite Books Yet',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B5B7B),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Tap "Add to Favourites" on a book '
                    'to save it here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF9A8FA3),
                ),
              ),
            ],
          ),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 22,
          childAspectRatio: 0.58,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];

          final String title =
              book['title'] ?? '';

          final String author =
              book['author'] ?? '';

          final String genre =
              book['genre'] ?? '';

          final String personality =
              book['personality'] ?? '';

          final String description =
              book['description'] ?? '';

          final String fileURL =
              book['fileURL'] ?? '';

          // GET LOCAL COVER USING BOOK TITLE
          final String localCover =
          _getCoverImage(title);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BookDetailsScreen(
                        title: title,
                        author: author,
                        genre: genre,
                        subGenre: '',
                        emoji: '📚',
                        color: const Color(0xFFE8DDF1),
                        personality: personality,
                        description: description,

                        // SEND LOCAL COVER
                        coverImage: localCover,

                        fileURL: fileURL,
                      ),
                ),
              );
            },

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFFE8DDF1),
                      borderRadius:
                      BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.06),
                          blurRadius: 10,
                          offset:
                          const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Stack(
                      children: [
                        // BOOK COVER
                        ClipRRect(
                          borderRadius:
                          BorderRadius.circular(18),

                          child: localCover.isNotEmpty
                              ? Image.asset(
                            localCover,
                            width:
                            double.infinity,
                            height:
                            double.infinity,
                            fit: BoxFit.cover,

                            errorBuilder: (
                                context,
                                error,
                                stackTrace,
                                ) {
                              return const Center(
                                child: Icon(
                                  Icons
                                      .menu_book_rounded,
                                  size: 55,
                                  color:
                                  Color(
                                    0xFFC8B6E2,
                                  ),
                                ),
                              );
                            },
                          )
                              : const Center(
                            child: Icon(
                              Icons
                                  .menu_book_rounded,
                              size: 55,
                              color:
                              Color(
                                0xFFC8B6E2,
                              ),
                            ),
                          ),
                        ),

                        // REMOVE BUTTON
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration:
                            const BoxDecoration(
                              color: Colors.white,
                              shape:
                              BoxShape.circle,
                            ),
                            child: IconButton(
                              padding:
                              EdgeInsets.zero,
                              constraints:
                              const BoxConstraints(
                                minWidth: 38,
                                minHeight: 38,
                              ),
                              icon: const Icon(
                                Icons
                                    .favorite_rounded,
                                color: Colors.pink,
                                size: 21,
                              ),
                              onPressed: () {
                                _removeFavouriteBook(
                                  index,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  title,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily:
                    'Times New Roman',
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF6B5B7B),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  author,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily:
                    'Times New Roman',
                    fontSize: 12,
                    color:
                    Color(0xFF9A8FA3),
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