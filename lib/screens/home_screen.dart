import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'recommendations_screen.dart';
import 'favourite_books_screen.dart';
import 'pdf_reader_screen.dart';
import 'audiobook_screen.dart';
import 'explore_screen.dart';
import 'book_details_screen.dart';
import 'profile_screen.dart';
import '../services/reading_progress_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  // ==================================================
  // CURRENT / CONTINUE READING BOOK
  // ==================================================

  String currentBookTitle = '';
  String currentBookAuthor = 'Book Author';
  String currentBookPersonality = 'Reading Journey';
  String currentBookPdfPath = '';

  int currentPage = 1;
  int totalPages = 0;

  bool isLoadingContinueReading = true;

  // ==================================================
  // CURRENT / CONTINUE LISTENING BOOK
  // ==================================================

  String listeningBookTitle = '';
  String listeningBookAuthor = 'Book Author';
  String listeningBookPdfPath = '';
  String listeningBookCoverImage = '';

  int listeningCurrentChunk = 0;
  int listeningTotalChunks = 0;

  double listeningProgress = 0.0;

  bool isLoadingContinueListening = true;

  // ==================================================
  // FIRESTORE BOOKS
  // ==================================================

  List<Map<String, dynamic>> recommendedBooks = [];

  bool isLoadingBooks = true;

  // ==================================================
  // SOFT BACKGROUND ANIMATION
  // ==================================================

  late AnimationController _auraController;

  late Animation<double> _auraAnimation;

  @override
  void initState() {
    super.initState();

    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2600,
      ),
    )..repeat(reverse: true);

    _auraAnimation = Tween<double>(
      begin: 0.72,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _auraController,
        curve: Curves.easeInOut,
      ),
    );

    _loadRecommendedBooks();

    _loadContinueReading();

    _loadContinueListening();
  }

  @override
  void dispose() {
    _auraController.dispose();

    super.dispose();
  }

  // ==================================================
  // LOAD CONTINUE READING FROM FIREBASE
  // ==================================================

  Future<void> _loadContinueReading() async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          isLoadingContinueReading = false;

          currentBookTitle = '';

          currentBookPdfPath = '';
        });

        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('reading_history')
          .where(
        'userId',
        isEqualTo: user.uid,
      )
          .get();

      if (snapshot.docs.isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoadingContinueReading = false;

          currentBookTitle = '';

          currentBookPdfPath = '';
        });

        return;
      }

      final documents = snapshot.docs.toList();

      documents.sort((a, b) {
        final Timestamp? dateA =
        a.data()['lastRead'] as Timestamp?;

        final Timestamp? dateB =
        b.data()['lastRead'] as Timestamp?;

        if (dateA == null && dateB == null) {
          return 0;
        }

        if (dateA == null) {
          return 1;
        }

        if (dateB == null) {
          return -1;
        }

        return dateB.compareTo(dateA);
      });

      final data = documents.first.data();

      final String title =
          data['title']?.toString() ?? '';

      final String author =
          data['author']?.toString() ??
              'Book Author';

      final String personality =
          data['personality']?.toString() ??
              'Reading Journey';

      final int savedCurrentPage =
      data['currentPage'] is int
          ? data['currentPage'] as int
          : int.tryParse(
        data['currentPage']
            ?.toString() ??
            '',
      ) ??
          1;

      final int savedTotalPages =
      data['totalPages'] is int
          ? data['totalPages'] as int
          : int.tryParse(
        data['totalPages']
            ?.toString() ??
            '',
      ) ??
          0;

      // ------------------------------------------------
      // FIND THE EXACT PDF FOR THIS BOOK
      // ------------------------------------------------

      String pdfPath = '';

      if (title.isNotEmpty) {
        final bookSnapshot =
        await FirebaseFirestore.instance
            .collection('books')
            .where(
          'title',
          isEqualTo: title,
        )
            .limit(1)
            .get();

        if (bookSnapshot.docs.isNotEmpty) {
          final bookData =
          bookSnapshot.docs.first.data();

          pdfPath =
              bookData['fileURL']
                  ?.toString()
                  .trim() ??
                  '';
        }
      }

      if (!mounted) return;

      setState(() {
        currentBookTitle = title;

        currentBookAuthor = author;

        currentBookPersonality =
            personality;

        currentBookPdfPath = pdfPath;

        currentPage =
        savedCurrentPage < 1
            ? 1
            : savedCurrentPage;

        totalPages =
        savedTotalPages < 0
            ? 0
            : savedTotalPages;

        isLoadingContinueReading = false;
      });

      debugPrint(
        'Continue Reading: '
            '$currentBookTitle '
            '(Page $currentPage '
            'of $totalPages)',
      );

      debugPrint(
        'Continue Reading PDF: '
            '$currentBookPdfPath',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingContinueReading = false;

        currentBookTitle = '';

        currentBookPdfPath = '';
      });

      debugPrint(
        'Error loading Continue Reading: $e',
      );
    }
  }

  // ==================================================
  // LOAD CONTINUE LISTENING FROM FIREBASE
  // ==================================================

  Future<void> _loadContinueListening() async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          isLoadingContinueListening = false;

          listeningBookTitle = '';

          listeningBookPdfPath = '';
        });

        return;
      }

      // ------------------------------------------------
      // AUDIOBOOK HISTORY
      // ------------------------------------------------

      final snapshot =
      await FirebaseFirestore.instance
          .collection('audiobook_history')
          .where(
        'userId',
        isEqualTo: user.uid,
      )
          .get();

      if (snapshot.docs.isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoadingContinueListening = false;

          listeningBookTitle = '';

          listeningBookPdfPath = '';
        });

        return;
      }

      final documents =
      snapshot.docs.toList();

      // ------------------------------------------------
      // GET MOST RECENTLY LISTENED BOOK
      // ------------------------------------------------

      documents.sort((a, b) {
        final Timestamp? dateA =
        a.data()['lastListenedAt']
        as Timestamp?;

        final Timestamp? dateB =
        b.data()['lastListenedAt']
        as Timestamp?;

        if (dateA == null && dateB == null) {
          return 0;
        }

        if (dateA == null) {
          return 1;
        }

        if (dateB == null) {
          return -1;
        }

        return dateB.compareTo(dateA);
      });

      final data =
      documents.first.data();

      // ------------------------------------------------
      // CHECK IF BOOK IS COMPLETED
      // ------------------------------------------------

      final bool isCompleted =
          data['isCompleted'] == true;

      if (isCompleted) {
        if (!mounted) return;

        setState(() {
          isLoadingContinueListening = false;

          listeningBookTitle = '';

          listeningBookPdfPath = '';
        });

        return;
      }

      // ------------------------------------------------
      // GET AUDIOBOOK INFORMATION
      // ------------------------------------------------

      final String title =
          data['title']?.toString() ?? '';

      final String author =
          data['author']?.toString() ??
              'Book Author';

      final String savedPdfPath =
          data['pdfPath']
              ?.toString()
              .trim() ??
              '';

      final String savedCoverImage =
          data['coverImage']
              ?.toString()
              .trim() ??
              '';

      final int currentChunk =
      data['currentChunk'] is int
          ? data['currentChunk'] as int
          : int.tryParse(
        data['currentChunk']
            ?.toString() ??
            '',
      ) ??
          0;

      final int totalChunks =
      data['totalChunks'] is int
          ? data['totalChunks'] as int
          : int.tryParse(
        data['totalChunks']
            ?.toString() ??
            '',
      ) ??
          0;

      // ------------------------------------------------
      // GET SAVED PROGRESS
      // ------------------------------------------------

      double savedProgress = 0.0;

      if (data['progress'] is num) {
        savedProgress =
            (data['progress'] as num)
                .toDouble();
      } else {
        savedProgress =
            double.tryParse(
              data['progress']
                  ?.toString() ??
                  '',
            ) ??
                0.0;
      }

      // ------------------------------------------------
      // CALCULATE PROGRESS IF NOT AVAILABLE
      // ------------------------------------------------

      if (savedProgress <= 0 &&
          totalChunks > 0) {
        savedProgress =
            currentChunk / totalChunks;
      }

      savedProgress =
          savedProgress.clamp(
            0.0,
            1.0,
          );

      // ------------------------------------------------
      // FIND PDF FROM BOOK COLLECTION IF NEEDED
      // ------------------------------------------------

      String pdfPath = savedPdfPath;

      if (pdfPath.isEmpty &&
          title.isNotEmpty) {
        final bookSnapshot =
        await FirebaseFirestore.instance
            .collection('books')
            .where(
          'title',
          isEqualTo: title,
        )
            .limit(1)
            .get();

        if (bookSnapshot.docs.isNotEmpty) {
          final bookData =
          bookSnapshot.docs.first.data();

          pdfPath =
              bookData['fileURL']
                  ?.toString()
                  .trim() ??
                  '';
        }
      }

      // ------------------------------------------------
      // GET COVER IMAGE
      // ------------------------------------------------

      String coverImage =
          savedCoverImage;

      if (coverImage.isEmpty) {
        coverImage =
            _getCoverImage(title);
      }

      if (!mounted) return;

      setState(() {
        listeningBookTitle = title;

        listeningBookAuthor = author;

        listeningBookPdfPath = pdfPath;

        listeningBookCoverImage =
            coverImage;

        listeningCurrentChunk =
            currentChunk;

        listeningTotalChunks =
            totalChunks;

        listeningProgress =
            savedProgress;

        isLoadingContinueListening =
        false;
      });

      debugPrint(
        'Continue Listening: '
            '$listeningBookTitle',
      );

      debugPrint(
        'Audiobook Chunk: '
            '$listeningCurrentChunk '
            'of $listeningTotalChunks',
      );

      debugPrint(
        'Audiobook Progress: '
            '${(listeningProgress * 100).round()}%',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingContinueListening = false;

        listeningBookTitle = '';

        listeningBookPdfPath = '';
      });

      debugPrint(
        'Error loading Continue Listening: $e',
      );
    }
  }

  // ==================================================
  // LOAD BOOKS FROM FIRESTORE
  // ==================================================

  Future<void> _loadRecommendedBooks() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance
          .collection('books')
          .get();

      final books =
      snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,

          'title':
          data['title']
              ?.toString() ??
              '',

          'author':
          data['author']
              ?.toString() ??
              '',

          'genre':
          data['genre']
              ?.toString() ??
              '',

          'subGenre':
          data['subGenre']
              ?.toString() ??
              '',

          'personality':
          data['personality']
              ?.toString() ??
              '',

          'description':
          data['description']
              ?.toString() ??
              '',

          'coverImage':
          data['coverImage']
              ?.toString()
              .trim() ??
              '',

          'fileURL':
          data['fileURL']
              ?.toString()
              .trim() ??
              '',
        };
      }).where((book) {
        return book['title']
            .toString()
            .isNotEmpty;
      }).toList();

      if (!mounted) return;

      setState(() {
        recommendedBooks = books;

        isLoadingBooks = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        recommendedBooks = [];

        isLoadingBooks = false;
      });

      debugPrint(
        'Error loading books from Firestore: $e',
      );
    }
  }

  // ==================================================
  // GET LOCAL COVER IMAGE
  // ==================================================

  String _getCoverImage(String title) {
    final value =
    title.toLowerCase().trim();

    if (value.contains(
        'hound of the baskervilles')) {
      return 'assets/covers/'
          'the_hound_of_the_baskervilles.jpg';
    }

    if (value.contains(
        'adventure of sherlock holmes') ||
        value.contains(
            'adventures of sherlock holmes')) {
      return 'assets/covers/'
          'the_adventure_of_sherlock_holmes.jpg';
    }

    if (value.contains('great gatsby')) {
      return 'assets/covers/'
          'the_great_gatsby.jpg';
    }

    if (value.contains(
        'pride and prejudice') ||
        value.contains(
            'pride & prejudice')) {
      return 'assets/covers/'
          'pride_and_prejudice.jpg';
    }

    if (value.contains('little women')) {
      return 'assets/covers/'
          'little_women.jpg';
    }

    if (value.contains('frankenstein')) {
      return 'assets/covers/'
          'frankenstein.jpg';
    }

    if (value.contains('dracula')) {
      return 'assets/covers/'
          'dracula.jpg';
    }

    if (value.contains(
        'alice in wonderland') ||
        value.contains(
            "alice's adventures in wonderland")) {
      return 'assets/covers/'
          'alice_in_wonderland.jpg';
    }

    return '';
  }

  // ==================================================
  // GET BOOK COLOR
  // ==================================================

  Color _getBookColor(
      String genre,
      String personality,
      ) {
    final value =
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

    return const Color(0xFFE8DDF1);
  }

  // ==================================================
  // GET BOOK EMOJI
  // ==================================================

  String _getBookEmoji(
      String genre,
      String personality,
      ) {
    final value =
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
        value.contains('detective') ||
        value.contains('thriller')) {
      return '🔍';
    }

    if (value.contains('horror') ||
        value.contains('dark')) {
      return '🌑';
    }

    if (value.contains('fantasy') ||
        value.contains('adventure')) {
      return '✨';
    }

    if (value.contains('fiction')) {
      return '📖';
    }

    return '📚';
  }

  // ==================================================
  // PASTEL BACKGROUND DECORATION
  // ==================================================

  Widget _buildBackgroundDecoration() {
    return IgnorePointer(
      child: Stack(
        children: [

          // TOP RIGHT LAVENDER AURA
          Positioned(
            top: -100,
            right: -90,
            child: AnimatedBuilder(
              animation: _auraAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity:
                  _auraAnimation.value *
                      0.35,
                  child: Container(
                    height: 260,
                    width: 260,
                    decoration:
                    const BoxDecoration(
                      shape:
                      BoxShape.circle,
                      color:
                      Color(0xFFC8B6E2),
                    ),
                  ),
                );
              },
            ),
          ),

          // TOP LEFT SOFT PINK CIRCLE
          Positioned(
            top: 185,
            left: -105,
            child: AnimatedBuilder(
              animation: _auraAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity:
                  _auraAnimation.value *
                      0.24,
                  child: Container(
                    height: 190,
                    width: 190,
                    decoration:
                    const BoxDecoration(
                      shape:
                      BoxShape.circle,
                      color:
                      Color(0xFFF7DDE7),
                    ),
                  ),
                );
              },
            ),
          ),

          // BOTTOM RIGHT PEACH CIRCLE
          Positioned(
            bottom: 80,
            right: -100,
            child: AnimatedBuilder(
              animation: _auraAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity:
                  _auraAnimation.value *
                      0.22,
                  child: Container(
                    height: 220,
                    width: 220,
                    decoration:
                    const BoxDecoration(
                      shape:
                      BoxShape.circle,
                      color:
                      Color(0xFFFFE7B8),
                    ),
                  ),
                );
              },
            ),
          ),

          // SMALL LAVENDER CIRCLE
          Positioned(
            top: 315,
            right: 35,
            child: AnimatedBuilder(
              animation: _auraAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale:
                  0.9 +
                      (_auraAnimation.value *
                          0.12),
                  child: Opacity(
                    opacity: 0.30,
                    child: Container(
                      height: 38,
                      width: 38,
                      decoration:
                      const BoxDecoration(
                        shape:
                        BoxShape.circle,
                        color:
                        Color(0xFFD8C5E8),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // SMALL PINK CIRCLE
          Positioned(
            top: 500,
            left: 18,
            child: AnimatedBuilder(
              animation: _auraAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale:
                  0.9 +
                      (_auraAnimation.value *
                          0.10),
                  child: Opacity(
                    opacity: 0.30,
                    child: Container(
                      height: 27,
                      width: 27,
                      decoration:
                      const BoxDecoration(
                        shape:
                        BoxShape.circle,
                        color:
                        Color(0xFFF2C9D8),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // DECORATIVE STARS
          const Positioned(
            top: 105,
            left: 65,
            child: Text(
              '✦',
              style: TextStyle(
                fontSize: 18,
                color:
                Color(0xFFC8B6E2),
              ),
            ),
          ),

          const Positioned(
            top: 240,
            right: 75,
            child: Text(
              '✧',
              style: TextStyle(
                fontSize: 23,
                color:
                Color(0xFFD9C5E8),
              ),
            ),
          ),

          const Positioned(
            top: 585,
            right: 45,
            child: Text(
              '✦',
              style: TextStyle(
                fontSize: 14,
                color:
                Color(0xFFE1C4D5),
              ),
            ),
          ),

          const Positioned(
            bottom: 165,
            left: 55,
            child: Text(
              '✧',
              style: TextStyle(
                fontSize: 19,
                color:
                Color(0xFFD8C5E8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {

    double progress = 0;

    if (totalPages > 0) {
      progress =
          currentPage / totalPages;

      if (progress > 1) {
        progress = 1;
      }

      if (progress < 0) {
        progress = 0;
      }
    }

    final int percentage =
    (progress * 100).round();

    final int listeningPercentage =
    (listeningProgress * 100).round();

    return Scaffold(
      backgroundColor:
      const Color(0xFFFFF9FC),

      // ==================================================
      // BOTTOM NAVIGATION BAR
      // ==================================================

      bottomNavigationBar:
      BottomNavigationBar(
        type:
        BottomNavigationBarType.fixed,

        backgroundColor:
        Colors.white,

        selectedItemColor:
        const Color(0xFF8B739F),

        unselectedItemColor:
        const Color(0xFFB9ADBF),

        currentIndex: 0,

        onTap: (index) {

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                const ExploreScreen(),
              ),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                const FavouriteBooksScreen(),
              ),
            );
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                const ProfileScreen(),
              ),
            );
          }
        },

        items: const [

          BottomNavigationBarItem(
            icon:
            Icon(Icons.home_rounded),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon:
            Icon(
              Icons.explore_outlined,
            ),
            label: 'Explore',
          ),

          BottomNavigationBarItem(
            icon:
            Icon(
              Icons.favorite_border_rounded,
            ),
            label: 'Favourites',
          ),

          BottomNavigationBarItem(
            icon:
            Icon(
              Icons.person_outline_rounded,
            ),
            label: 'Profile',
          ),
        ],
      ),

      // ==================================================
      // HOME BODY
      // ==================================================

      body: SafeArea(
        child: Stack(
          children: [

            // PASTEL BACKGROUND
            _buildBackgroundDecoration(),

            // HOME CONTENT
            SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 18,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  // ==================================================
                  // GREETING
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                    children: [

                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: const [

                          Text(
                            'Hello, Reader! ✨',
                            style:
                            TextStyle(
                              fontSize: 27,
                              fontWeight:
                              FontWeight.w700,
                              color:
                              Color(
                                0xFF6B5B7B,
                              ),
                            ),
                          ),

                          SizedBox(
                            height: 6,
                          ),

                          Text(
                            'Welcome to your reading space',
                            style:
                            TextStyle(
                              fontSize: 14,
                              color:
                              Color(
                                0xFF9A8FA3,
                              ),
                            ),
                          ),
                        ],
                      ),

                      Container(
                        height: 48,
                        width: 48,

                        decoration:
                        const BoxDecoration(
                          color:
                          Color(
                            0xFFE8DDF1,
                          ),
                          shape:
                          BoxShape.circle,
                        ),

                        child:
                        const Icon(
                          Icons
                              .person_outline_rounded,
                          color:
                          Color(
                            0xFF6B5B7B,
                          ),
                          size: 27,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  // ==================================================
                  // SEARCH BAR
                  // ==================================================

                  Container(
                    height: 55,

                    decoration:
                    BoxDecoration(
                      color:
                      Colors.white,

                      borderRadius:
                      BorderRadius
                          .circular(
                        18,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors
                              .black
                              .withOpacity(
                            0.04,
                          ),
                          blurRadius: 10,
                        ),
                      ],
                    ),

                    child:
                    const TextField(
                      decoration:
                      InputDecoration(
                        hintText:
                        'Search books, authors...',

                        hintStyle:
                        TextStyle(
                          color:
                          Color(
                            0xFFB5AAB9,
                          ),
                        ),

                        prefixIcon:
                        Icon(
                          Icons
                              .search_rounded,
                          color:
                          Color(
                            0xFFC8B6E2,
                          ),
                        ),

                        border:
                        InputBorder.none,

                        contentPadding:
                        EdgeInsets
                            .symmetric(
                          vertical: 17,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  // ==================================================
                  // MOOD SECTION
                  // ==================================================

                  const Text(
                    'How are you feeling today?',
                    style:
                    TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(
                        0xFF6B5B7B,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Text(
                    'Choose a mood and discover books that match your vibe.',
                    style:
                    TextStyle(
                      fontSize: 14,
                      color:
                      Color(
                        0xFF9A8FA3,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  SizedBox(
                    height: 115,

                    child: ListView(
                      scrollDirection:
                      Axis.horizontal,

                      children: [

                        _moodCard(
                          context,
                          'Happy',
                          '😊',
                          const Color(
                            0xFFFFE7B8,
                          ),
                        ),

                        _moodCard(
                          context,
                          'Calm',
                          '🌸',
                          const Color(
                            0xFFE8DDF1,
                          ),
                        ),

                        _moodCard(
                          context,
                          'Romantic',
                          '💗',
                          const Color(
                            0xFFF7DDE7,
                          ),
                        ),

                        _moodCard(
                          context,
                          'Sad',
                          '🌧️',
                          const Color(
                            0xFFDDEAF5,
                          ),
                        ),

                        _moodCard(
                          context,
                          'Motivated',
                          '✨',
                          const Color(
                            0xFFFFDFC8,
                          ),
                        ),

                        _moodCard(
                          context,
                          'Peaceful',
                          '🌿',
                          const Color(
                            0xFFDDEBDD,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 32,
                  ),

                  // ==================================================
                  // RECOMMENDED BOOKS
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                    children: [

                      const Text(
                        'Recommended for You',
                        style:
                        TextStyle(
                          fontSize: 20,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Color(
                            0xFF6B5B7B,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                              const ExploreScreen(),
                            ),
                          );
                        },

                        child:
                        const Text(
                          'See All',
                          style:
                          TextStyle(
                            color:
                            Color(
                              0xFF8B739F,
                            ),
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  SizedBox(
                    height: 250,

                    child: isLoadingBooks

                        ? const Center(
                      child:
                      CircularProgressIndicator(
                        color:
                        Color(
                          0xFFC8B6E2,
                        ),
                      ),
                    )

                        : recommendedBooks
                        .isEmpty

                        ? const Center(
                      child:
                      Text(
                        'No books available 📚',
                        style:
                        TextStyle(
                          fontSize: 14,
                          color:
                          Color(
                            0xFF9A8FA3,
                          ),
                        ),
                      ),
                    )

                        : ListView(
                      scrollDirection:
                      Axis.horizontal,

                      children:
                      recommendedBooks
                          .map(
                            (book) {

                          final String
                          title =
                              book['title']
                                  ?.toString() ??
                                  '';

                          final String
                          author =
                              book['author']
                                  ?.toString() ??
                                  '';

                          final String
                          genre =
                              book['genre']
                                  ?.toString() ??
                                  '';

                          final String
                          subGenre =
                              book['subGenre']
                                  ?.toString() ??
                                  '';

                          final String
                          personality =
                              book['personality']
                                  ?.toString() ??
                                  '';

                          final String
                          description =
                              book['description']
                                  ?.toString() ??
                                  '';

                          final String
                          fileURL =
                              book['fileURL']
                                  ?.toString()
                                  .trim() ??
                                  '';

                          final String
                          coverImage =
                          _getCoverImage(
                            title,
                          );

                          return _bookCard(
                            context,
                            title,
                            author,
                            _getBookColor(
                              genre,
                              personality,
                            ),
                            _getBookEmoji(
                              genre,
                              personality,
                            ),
                            genre,
                            personality,
                            description,
                            subGenre,
                            coverImage,
                            fileURL,
                          );
                        },
                      ).toList(),
                    ),
                  ),

                  const SizedBox(
                    height: 32,
                  ),

                  // ==================================================
                  // CONTINUE READING
                  // ==================================================

                  const Text(
                    'Continue Reading',
                    style:
                    TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(
                        0xFF6B5B7B,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  GestureDetector(
                    onTap:
                    currentBookTitle
                        .isEmpty ||
                        currentBookPdfPath
                            .isEmpty
                        ? null
                        : () async {

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                              PdfReaderScreen(
                                title:
                                currentBookTitle,
                                pdfPath:
                                currentBookPdfPath,
                              ),
                        ),
                      );

                      await _loadContinueReading();
                    },

                    child:
                    Container(
                      padding:
                      const EdgeInsets.all(
                        18,
                      ),

                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xFFE8DDF1,
                        ),

                        borderRadius:
                        BorderRadius
                            .circular(
                          22,
                        ),
                      ),

                      child:
                      Row(
                        children: [

                          // BOOK COVER
                          Container(
                            height: 100,
                            width: 72,

                            decoration:
                            BoxDecoration(
                              color:
                              const Color(
                                0xFFC8B6E2,
                              ),

                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),
                            ),

                            child:
                            ClipRRect(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),

                              child:
                              _getCoverImage(
                                  currentBookTitle)
                                  .isNotEmpty

                                  ? Image.asset(
                                _getCoverImage(
                                  currentBookTitle,
                                ),

                                height:
                                100,

                                width:
                                72,

                                fit: BoxFit
                                    .cover,

                                errorBuilder:
                                    (
                                    context,
                                    error,
                                    stackTrace,
                                    ) {
                                  return const Center(
                                    child:
                                    Icon(
                                      Icons
                                          .menu_book_rounded,
                                      color:
                                      Colors.white,
                                      size:
                                      35,
                                    ),
                                  );
                                },
                              )

                                  : const Center(
                                child:
                                Icon(
                                  Icons
                                      .menu_book_rounded,
                                  color:
                                  Colors.white,
                                  size:
                                  35,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 16,
                          ),

                          // BOOK DETAILS
                          Expanded(
                            child:
                            isLoadingContinueReading

                                ? const Center(
                              child:
                              SizedBox(
                                height:
                                22,
                                width:
                                22,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth:
                                  2,
                                  color:
                                  Color(
                                    0xFF8B739F,
                                  ),
                                ),
                              ),
                            )

                                : currentBookTitle
                                .isEmpty

                                ? const Text(
                              'Start reading a book to see it here 📖',
                              style:
                              TextStyle(
                                fontSize:
                                14,
                                color:
                                Color(
                                  0xFF9A8FA3,
                                ),
                              ),
                            )

                                : Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,

                              children: [

                                const Text(
                                  'Your Current Book',
                                  style:
                                  TextStyle(
                                    fontSize:
                                    12,
                                    color:
                                    Color(
                                      0xFF8B739F,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                  5,
                                ),

                                Text(
                                  currentBookTitle,
                                  maxLines:
                                  1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    18,
                                    fontWeight:
                                    FontWeight.w700,
                                    color:
                                    Color(
                                      0xFF6B5B7B,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                  12,
                                ),

                                ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(
                                    10,
                                  ),

                                  child:
                                  LinearProgressIndicator(
                                    value:
                                    progress,
                                    minHeight:
                                    7,
                                    backgroundColor:
                                    Colors.white,
                                    color:
                                    const Color(
                                      0xFFC8B6E2,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                  7,
                                ),

                                Text(
                                  '$percentage% completed',
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    12,
                                    color:
                                    Color(
                                      0xFF9A8FA3,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                  3,
                                ),

                                Text(
                                  totalPages >
                                      0
                                      ? 'Page $currentPage of $totalPages'
                                      : 'Page $currentPage',
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    11,
                                    color:
                                    Color(
                                      0xFF9A8FA3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ==================================================
                  // CONTINUE LISTENING
                  // ==================================================

                  const SizedBox(
                    height: 30,
                  ),

                  const Text(
                    'Continue Listening',
                    style:
                    TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(
                        0xFF6B5B7B,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  GestureDetector(
                    onTap:
                    listeningBookTitle
                        .isEmpty ||
                        listeningBookPdfPath
                            .isEmpty
                        ? null
                        : () async {

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                              AudiobookScreen(
                                title:
                                listeningBookTitle,
                                pdfPath:
                                listeningBookPdfPath,
                              ),
                        ),
                      );

                      await _loadContinueListening();
                    },

                    child:
                    Container(
                      padding:
                      const EdgeInsets.all(
                        18,
                      ),

                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xFFF7DDE7,
                        ),

                        borderRadius:
                        BorderRadius
                            .circular(
                          22,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .black
                                .withOpacity(
                              0.035,
                            ),
                            blurRadius: 10,
                            offset:
                            const Offset(
                              0,
                              4,
                            ),
                          ),
                        ],
                      ),

                      child:
                      Row(
                        children: [

                          // ==================================================
                          // AUDIOBOOK COVER
                          // ==================================================

                          Container(
                            height: 105,
                            width: 76,

                            decoration:
                            BoxDecoration(
                              color:
                              const Color(
                                0xFFE8C8D7,
                              ),

                              borderRadius:
                              BorderRadius
                                  .circular(
                                13,
                              ),
                            ),

                            child:
                            ClipRRect(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                13,
                              ),

                              child:
                              listeningBookCoverImage
                                  .isNotEmpty

                                  ? Image.asset(
                                listeningBookCoverImage,

                                height:
                                105,

                                width:
                                76,

                                fit: BoxFit
                                    .cover,

                                errorBuilder:
                                    (
                                    context,
                                    error,
                                    stackTrace,
                                    ) {
                                  return const Center(
                                    child:
                                    Icon(
                                      Icons
                                          .headphones_rounded,
                                      color:
                                      Colors.white,
                                      size:
                                      36,
                                    ),
                                  );
                                },
                              )

                                  : const Center(
                                child:
                                Icon(
                                  Icons
                                      .headphones_rounded,
                                  color:
                                  Colors.white,
                                  size:
                                  36,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 16,
                          ),

                          // ==================================================
                          // AUDIOBOOK DETAILS
                          // ==================================================

                          Expanded(
                            child:
                            isLoadingContinueListening

                                ? const Center(
                              child:
                              SizedBox(
                                height:
                                22,
                                width:
                                22,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth:
                                  2,
                                  color:
                                  Color(
                                    0xFF8B739F,
                                  ),
                                ),
                              ),
                            )

                                : listeningBookTitle
                                .isEmpty

                                ? const Text(
                              'Listen to a book to see it here 🎧',
                              style:
                              TextStyle(
                                fontSize:
                                14,
                                color:
                                Color(
                                  0xFF9A8FA3,
                                ),
                              ),
                            )

                                : Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,

                              children: [

                                // AUDIO LABEL
                                Row(
                                  children: [

                                    const Icon(
                                      Icons
                                          .headphones_rounded,
                                      size:
                                      16,
                                      color:
                                      Color(
                                        0xFF8B739F,
                                      ),
                                    ),

                                    const SizedBox(
                                      width:
                                      5,
                                    ),

                                    const Text(
                                      'Continue Listening',
                                      style:
                                      TextStyle(
                                        fontSize:
                                        12,
                                        fontWeight:
                                        FontWeight.w600,
                                        color:
                                        Color(
                                          0xFF8B739F,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height:
                                  6,
                                ),

                                // BOOK TITLE
                                Text(
                                  listeningBookTitle,
                                  maxLines:
                                  1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    18,
                                    fontWeight:
                                    FontWeight.w700,
                                    color:
                                    Color(
                                      0xFF6B5B7B,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                  4,
                                ),

                                // AUTHOR
                                Text(
                                  listeningBookAuthor,
                                  maxLines:
                                  1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    12,
                                    color:
                                    Color(
                                      0xFF9A8FA3,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                  12,
                                ),

                                // AUDIO PROGRESS
                                ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(
                                    10,
                                  ),

                                  child:
                                  LinearProgressIndicator(
                                    value:
                                    listeningProgress,
                                    minHeight:
                                    7,
                                    backgroundColor:
                                    Colors.white,
                                    color:
                                    const Color(
                                      0xFFC8B6E2,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                  7,
                                ),

                                // BOTTOM INFO
                                Row(
                                  children: [

                                    Expanded(
                                      child:
                                      Text(
                                        '$listeningPercentage% listened',
                                        style:
                                        const TextStyle(
                                          fontSize:
                                          11,
                                          color:
                                          Color(
                                            0xFF9A8FA3,
                                          ),
                                        ),
                                      ),
                                    ),

                                    Container(
                                      height:
                                      34,
                                      width:
                                      34,

                                      decoration:
                                      const BoxDecoration(
                                        color:
                                        Color(
                                          0xFFE8DDF1,
                                        ),
                                        shape:
                                        BoxShape.circle,
                                      ),

                                      child:
                                      const Icon(
                                        Icons
                                            .play_arrow_rounded,
                                        size:
                                        21,
                                        color:
                                        Color(
                                          0xFF6B5B7B,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // MOOD CARD
  // ==================================================

  static Widget _moodCard(
      BuildContext context,
      String mood,
      String emoji,
      Color backgroundColor,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RecommendationsScreen(
                  mood: mood,
                ),
          ),
        );
      },

      child:
      Container(
        width: 100,

        margin:
        const EdgeInsets.only(
          right: 12,
        ),

        decoration:
        BoxDecoration(
          color:
          backgroundColor,

          borderRadius:
          BorderRadius
              .circular(
            20,
          ),
        ),

        child:
        Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,

          children: [

            Text(
              emoji,
              style:
              const TextStyle(
                fontSize: 30,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              mood,
              style:
              const TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.w600,
                color:
                Color(
                  0xFF6B5B7B,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // BOOK CARD
  // ==================================================

  static Widget _bookCard(
      BuildContext context,
      String title,
      String author,
      Color coverColor,
      String emoji,
      String genre,
      String personality,
      String description,
      String subGenre,
      String coverImage,
      String fileURL,
      ) {
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
                  subGenre: subGenre,
                  emoji: emoji,
                  color: coverColor,
                  personality:
                  personality,
                  description:
                  description,
                  coverImage:
                  coverImage,
                  fileURL:
                  fileURL,
                ),
          ),
        );
      },

      child:
      Container(
        width: 155,

        margin:
        const EdgeInsets.only(
          right: 15,
        ),

        child:
        Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .start,

          children: [

            Container(
              height: 175,
              width: 155,

              decoration:
              BoxDecoration(
                color:
                coverColor,

                borderRadius:
                BorderRadius
                    .circular(
                  18,
                ),
              ),

              child:
              ClipRRect(
                borderRadius:
                BorderRadius
                    .circular(
                  18,
                ),

                child:
                coverImage.isNotEmpty

                    ? Image.asset(
                  coverImage,

                  height:
                  175,

                  width:
                  155,

                  fit: BoxFit
                      .cover,

                  errorBuilder:
                      (
                      context,
                      error,
                      stackTrace,
                      ) {
                    return Center(
                      child:
                      Text(
                        emoji,
                        style:
                        const TextStyle(
                          fontSize:
                          48,
                        ),
                      ),
                    );
                  },
                )

                    : Center(
                  child:
                  Text(
                    emoji,
                    style:
                    const TextStyle(
                      fontSize:
                      48,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              title,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,

              style:
              const TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight.w700,
                color:
                Color(
                  0xFF6B5B7B,
                ),
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              author,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,

              style:
              const TextStyle(
                fontSize: 12,
                color:
                Color(
                  0xFF9A8FA3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}