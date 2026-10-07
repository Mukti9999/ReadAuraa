import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'book_details_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  final String mood;

  const RecommendationsScreen({
    super.key,
    required this.mood,
  });

  @override
  State<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState
    extends State<RecommendationsScreen> {
  List<Map<String, dynamic>> books = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _saveMoodToFirebase();
    _loadBooksForMood();
  }

  // SAVE SELECTED MOOD TO FIREBASE
  Future<void> _saveMoodToFirebase() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      await FirebaseFirestore.instance
          .collection('mood')
          .doc(user.uid)
          .set(
        {
          'userId': user.uid,
          'selectedMood': widget.mood,
          'date': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error saving mood: $e');
    }
  }

  // LOAD BOOKS FROM FIRESTORE
  Future<void> _loadBooksForMood() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance
          .collection('books')
          .get();

      final List<Map<String, dynamic>> allBooks =
      snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'title': data['title']?.toString() ?? '',
          'author': data['author']?.toString() ?? '',
          'genre': data['genre']?.toString() ?? '',
          'subGenre': data['subGenre']?.toString() ?? '',
          'personality': data['personality']?.toString() ?? '',
          'description': data['description']?.toString() ?? '',
          'coverImage': data['coverImage']?.toString().trim() ?? '',
          'fileURL': data['fileURL']?.toString().trim() ?? '',
        };
      }).where((book) {
        return book['title'].toString().isNotEmpty;
      }).toList();

      final List<Map<String, dynamic>> matchedBooks =
      _filterBooksByMood(allBooks, widget.mood);

      if (!mounted) return;

      setState(() {
        books = matchedBooks;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      debugPrint('Error loading recommendations: $e');

      if (!mounted) return;

      setState(() {
        books = [];
        isLoading = false;
        errorMessage = 'Unable to load recommendations.';
      });
    }
  }

  // FILTER FIRESTORE BOOKS ACCORDING TO MOOD
  List<Map<String, dynamic>> _filterBooksByMood(
      List<Map<String, dynamic>> allBooks,
      String mood,
      ) {
    final Map<String, List<String>> moodKeywords = {
      'Romantic': [
        'romance',
        'romantic',
        'love',
        'classic romance',
      ],
      'Happy': [
        'heartwarming',
        'inspiring',
        'adventure',
        'fantasy',
      ],
      'Calm': [
        'inspiring',
        'heartwarming',
        'philosophical',
        'literary',
      ],
      'Sad': [
        'emotional',
        'thought-provoking',
        'dark',
      ],
      'Motivated': [
        'inspiring',
        'self-help',
        'habits',
        'productivity',
        'finance',
      ],
      'Peaceful': [
        'inspiring',
        'heartwarming',
        'philosophical',
      ],
    };

    final List<String> keywords = moodKeywords[mood] ?? [];

    final List<Map<String, dynamic>> matchedBooks = [];

    for (final book in allBooks) {
      final String genre =
      book['genre'].toString().toLowerCase();

      final String subGenre =
      book['subGenre'].toString().toLowerCase();

      final String personality =
      book['personality'].toString().toLowerCase();

      final String description =
      book['description'].toString().toLowerCase();

      int score = 0;

      for (final keyword in keywords) {
        if (genre.contains(keyword.toLowerCase())) {
          score += 3;
        }

        if (subGenre.contains(keyword.toLowerCase())) {
          score += 3;
        }

        if (personality.contains(keyword.toLowerCase())) {
          score += 5;
        }

        if (description.contains(keyword.toLowerCase())) {
          score += 1;
        }
      }

      if (score > 0) {
        final Map<String, dynamic> bookWithScore =
        Map<String, dynamic>.from(book);

        bookWithScore['_score'] = score;

        matchedBooks.add(bookWithScore);
      }
    }

    matchedBooks.sort((a, b) {
      final int scoreA = (a['_score'] ?? 0) as int;
      final int scoreB = (b['_score'] ?? 0) as int;

      return scoreB.compareTo(scoreA);
    });

    // If very few books match a mood,
    // show some generally suitable books instead
    if (matchedBooks.length < 2) {
      final List<Map<String, dynamic>> fallbackBooks =
      List<Map<String, dynamic>>.from(allBooks);

      fallbackBooks.sort((a, b) {
        final String personalityA =
        a['personality'].toString().toLowerCase();

        final String personalityB =
        b['personality'].toString().toLowerCase();

        if (personalityA.contains('inspiring') &&
            !personalityB.contains('inspiring')) {
          return -1;
        }

        if (!personalityA.contains('inspiring') &&
            personalityB.contains('inspiring')) {
          return 1;
        }

        return 0;
      });

      return fallbackBooks.take(3).toList();
    }

    return matchedBooks;
  }

  // GET LOCAL BOOK COVER
  String _getCoverImage(String title) {
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

  // BOOK COLOR BASED ON GENRE / PERSONALITY
  Color _getBookColor(
      String genre,
      String personality,
      ) {
    final String value =
    '$genre $personality'.toLowerCase();

    if (value.contains('romance')) {
      return const Color(0xFFF7DDE7);
    }

    if (value.contains('self-help') ||
        value.contains('inspiring') ||
        value.contains('finance')) {
      return const Color(0xFFDDEBDD);
    }

    if (value.contains('mystery') ||
        value.contains('detective') ||
        value.contains('thriller')) {
      return const Color(0xFFDDEAF5);
    }

    if (value.contains('horror') ||
        value.contains('dark')) {
      return const Color(0xFFE1D9E5);
    }

    if (value.contains('fantasy') ||
        value.contains('adventure')) {
      return const Color(0xFFFFE7B8);
    }

    if (value.contains('emotional')) {
      return const Color(0xFFDDEAF5);
    }

    return const Color(0xFFE8DDF1);
  }

  // BOOK EMOJI BASED ON GENRE / PERSONALITY
  String _getBookEmoji(
      String genre,
      String personality,
      ) {
    final String value =
    '$genre $personality'.toLowerCase();

    if (value.contains('romance')) {
      return '💗';
    }

    if (value.contains('self-help')) {
      return '🌿';
    }

    if (value.contains('finance')) {
      return '💰';
    }

    if (value.contains('mystery') ||
        value.contains('detective')) {
      return '🔍';
    }

    if (value.contains('thriller')) {
      return '😶‍🌫️';
    }

    if (value.contains('horror') ||
        value.contains('dark')) {
      return '🌑';
    }

    if (value.contains('fantasy') ||
        value.contains('adventure')) {
      return '✨';
    }

    if (value.contains('emotional')) {
      return '🌧️';
    }

    if (value.contains('inspiring')) {
      return '🌟';
    }

    return '📖';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FC),
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
        title: Text(
          '${widget.mood} Reads',
          style: const TextStyle(
            fontFamily: 'Times New Roman',
            color: Color(0xFF6B5B7B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Books for your ${widget.mood} mood ✨',
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getMoodDescription(widget.mood),
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 14,
                color: Color(0xFF9A8FA3),
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: _buildRecommendationBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC8B6E2),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 50,
              color: Color(0xFFB9ADBF),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 14,
                color: Color(0xFF9A8FA3),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });

                _loadBooksForMood();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8B6E2),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (books.isEmpty) {
      return const Center(
        child: Text(
          'No books found for this mood 📚',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 14,
            color: Color(0xFF9A8FA3),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final Map<String, dynamic> book = books[index];

        final String title =
            book['title']?.toString() ?? '';

        final String author =
            book['author']?.toString() ?? '';

        final String genre =
            book['genre']?.toString() ?? '';

        final String subGenre =
            book['subGenre']?.toString() ?? '';

        final String personality =
            book['personality']?.toString() ?? '';

        final String description =
            book['description']?.toString() ?? '';

        final String fileURL =
            book['fileURL']?.toString().trim() ?? '';

        // USE LOCAL COVER BASED ON BOOK TITLE
        final String localCover =
        _getCoverImage(title);

        final Color bookColor = _getBookColor(
          genre,
          personality,
        );

        final String emoji = _getBookEmoji(
          genre,
          personality,
        );

        return Container(
          margin: const EdgeInsets.only(
            bottom: 18,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bookColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              // BOOK COVER
              Container(
                height: 125,
                width: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: localCover.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    localCover,
                    height: 125,
                    width: 90,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(
                            fontSize: 42,
                          ),
                        ),
                      );
                    },
                  ),
                )
                    : Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: 42,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // BOOK DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B5B7B),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 13,
                        color: Color(0xFF8F8296),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                              Colors.white.withOpacity(0.5),
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                            child: Text(
                              genre,
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily:
                                'Times New Roman',
                                fontSize: 11,
                                color: Color(0xFF7D7183),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                              Colors.white.withOpacity(0.5),
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                            child: Text(
                              personality,
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily:
                                'Times New Roman',
                                fontSize: 11,
                                color: Color(0xFF7D7183),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF7D7183),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BookDetailsScreen(
                                    title: title,
                                    author: author,
                                    genre: genre,
                                    subGenre: subGenre,
                                    emoji: emoji,
                                    color: bookColor,
                                    personality: personality,
                                    description: description,
                                    coverImage: localCover,
                                    fileURL: fileURL,
                                  ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFFC8B6E2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Read Now',
                          style: TextStyle(
                            fontFamily: 'Times New Roman',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMoodDescription(String mood) {
    switch (mood) {
      case 'Romantic':
        return 'Soft stories filled with love, emotions and beautiful moments. 💗';

      case 'Happy':
        return 'Light and cheerful reads to brighten your day. 🌼';

      case 'Calm':
        return 'Peaceful stories for a slow and relaxing reading experience. 🌿';

      case 'Sad':
        return 'Emotional stories for moments when you want to feel understood. 🌧️';

      case 'Motivated':
        return 'Inspiring reads to give you energy and keep you moving forward. 🔥';

      case 'Peaceful':
        return 'Gentle reads for slowing down and finding a little calm. 🌙';

      default:
        return 'A few reads that might match your vibe. ✨';
    }
  }
}