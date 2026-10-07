import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pdf_reader_screen.dart';
import 'audiobook_screen.dart';
import 'login_screen.dart';

import '../services/favourite_books_service.dart';

class BookDetailsScreen extends StatelessWidget {
  final String title;
  final String author;
  final String genre;
  final String subGenre;
  final String emoji;
  final Color color;
  final String personality;
  final String description;
  final String coverImage;
  final String fileURL;

  const BookDetailsScreen({
    super.key,
    required this.title,
    required this.author,
    required this.genre,
    required this.subGenre,
    required this.emoji,
    required this.color,
    required this.personality,
    required this.description,
    required this.coverImage,
    required this.fileURL,
  });

  // --------------------------------------------------
  // PDF PATH
  // --------------------------------------------------

  String get pdfPath {
    final String path = fileURL.trim();

    if (path.isNotEmpty) {
      return path;
    }

    return 'assets/books/the_hound_of_the_baskervilles.pdf';
  }

  // --------------------------------------------------
  // LOCAL COVER PATH
  // --------------------------------------------------

  String get localCoverPath {
    final String value = title.toLowerCase().trim();

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

  // --------------------------------------------------
  // LOGIN REQUIRED POPUP
  // --------------------------------------------------

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF9FC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Login Required 🔐',
            style: TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B5B7B),
            ),
          ),
          content: const Text(
            'Please login first to read this book and continue your reading journey.',
            style: TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF7D7183),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  color: Color(0xFF9A8FA3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8B6E2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------
  // CHECK LOGIN
  // --------------------------------------------------

  bool _isLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FC),

      // --------------------------------------------------
      // APP BAR
      // --------------------------------------------------

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF6B5B7B),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Book Details',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            color: Color(0xFF6B5B7B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // --------------------------------------------------
      // BODY
      // --------------------------------------------------

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          22,
          10,
          22,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // COVER
            // --------------------------------------------------

            Center(
              child: Container(
                height: 250,
                width: 180,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: localCoverPath.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    localCoverPath,
                    height: 250,
                    width: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                        ) {
                      debugPrint(
                        'COVER ERROR: $localCoverPath',
                      );

                      debugPrint(
                        'ERROR DETAILS: $error',
                      );

                      return _fallbackCover();
                    },
                  ),
                )
                    : _fallbackCover(),
              ),
            ),

            const SizedBox(height: 28),

            // --------------------------------------------------
            // TITLE
            // --------------------------------------------------

            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'by $author',
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 15,
                color: Color(0xFF9A8FA3),
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // TAGS
            // --------------------------------------------------

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildTag(
                  icon: Icons.category_outlined,
                  text: genre,
                ),

                if (subGenre.trim().isNotEmpty)
                  _buildTag(
                    icon: Icons.label_outline_rounded,
                    text: subGenre,
                  ),

                _buildTag(
                  icon: Icons.auto_awesome,
                  text: personality,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // --------------------------------------------------
            // ABOUT
            // --------------------------------------------------

            const Text(
              'About the Book',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              description,
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF7D7183),
              ),
            ),

            const SizedBox(height: 30),

            // --------------------------------------------------
            // ADD TO FAVOURITES
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final FavouriteBookResult result =
                  await FavouriteBooksService.addFavouriteBook(
                    title: title,
                    author: author,
                    genre: genre,
                    personality: personality,
                    description: description,
                    coverImage: localCoverPath,
                    fileURL: fileURL,
                  );

                  if (!context.mounted) {
                    return;
                  }

                  String message;

                  switch (result) {
                    case FavouriteBookResult.added:
                      message = 'Book added to favourites ❤️';
                      break;

                    case FavouriteBookResult.alreadyExists:
                      message =
                      'This book is already in your favourites ❤️';
                      break;

                    case FavouriteBookResult.notLoggedIn:
                      message =
                      'Please log in to save favourites.';
                      break;

                    case FavouriteBookResult.error:
                      message =
                      'Couldn’t save favourite. Please try again.';
                      break;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        message,
                        style: const TextStyle(
                          fontFamily: 'Times New Roman',
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.favorite_border_rounded,
                ),
                label: const Text(
                  'Add to Favourites',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B5B7B),
                  side: const BorderSide(
                    color: Color(0xFFC8B6E2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // AUDIOBOOK
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  final String trimmedPath = fileURL.trim();

                  if (trimmedPath.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Audiobook is not available for this book yet.',
                          style: TextStyle(
                            fontFamily: 'Times New Roman',
                          ),
                        ),
                      ),
                    );

                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AudiobookScreen(
                        title: title,
                        pdfPath: pdfPath,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.record_voice_over_rounded,
                ),
                label: const Text(
                  'Listen as Audiobook 🎙️',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE7B8),
                  foregroundColor: const Color(0xFF6B5B7B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // READ NOW
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Guest user check
                  if (!_isLoggedIn()) {
                    _showLoginRequiredDialog(context);
                    return;
                  }

                  // Logged-in user
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfReaderScreen(
                        title: title,
                        pdfPath: pdfPath,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.menu_book_rounded,
                ),
                label: const Text(
                  'Read Now',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8B6E2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // FALLBACK COVER
  // --------------------------------------------------

  Widget _fallbackCover() {
    return Center(
      child: Text(
        emoji,
        style: const TextStyle(
          fontFamily: 'Times New Roman',
          fontSize: 70,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // TAG
  // --------------------------------------------------

  Widget _buildTag({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAF6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF7B6A8D),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7B6A8D),
            ),
          ),
        ],
      ),
    );
  }
}