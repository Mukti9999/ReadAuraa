import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_details_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String selectedGenre = 'All';
  String searchText = '';

  List<Map<String, dynamic>> books = [];
  bool isLoading = true;

  final List<String> genres = [
    'All',
    'Romance',
    'Fiction',
    'Self-Help',
    'Mystery',
    'Horror',
    'Fantasy',
    'Thriller',
    'Finance',
  ];

  @override
  void initState() {
    super.initState();
    _loadBooks();
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

  Future<void> _loadBooks() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('books').get();

      final loadedBooks = snapshot.docs.map((document) {
        final data = document.data();

        return {
          'id': document.id,
          'title': data['title']?.toString() ?? '',
          'author': data['author']?.toString() ?? '',
          'genre': data['genre']?.toString() ?? '',
          'subGenre': data['subGenre']?.toString() ?? '',
          'personality': data['personality']?.toString() ?? '',
          'description': data['description']?.toString() ?? '',
          'coverImage': data['coverImage']?.toString() ?? '',
          'fileURL': data['fileURL']?.toString() ?? '',
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        books = loadedBooks;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not load books. Please try again.',
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredBooks {
    return books.where((book) {
      final matchesGenre =
          selectedGenre == 'All' || book['genre'] == selectedGenre;

      final query = searchText.toLowerCase();

      final title = book['title']?.toString().toLowerCase() ?? '';
      final author = book['author']?.toString().toLowerCase() ?? '';

      final matchesSearch =
          title.contains(query) || author.contains(query);

      return matchesGenre && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayedBooks = filteredBooks;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FC),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9FC),
        elevation: 0,
        title: const Text(
          'Explore 📚',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            color: Color(0xFF6B5B7B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 5),

            const Text(
              'Find your next read ✨',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Explore books by genre or search for something specific.',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 14,
                color: Color(0xFF9A8FA3),
              ),
            ),

            const SizedBox(height: 18),

            // SEARCH BAR

            TextField(
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              style: const TextStyle(
                fontFamily: 'Times New Roman',
              ),
              decoration: InputDecoration(
                hintText: 'Search books or authors...',
                hintStyle: const TextStyle(
                  fontFamily: 'Times New Roman',
                  color: Color(0xFFAAA0B2),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF8F8296),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // GENRE TITLE

            const Text(
              'Genres',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 12),

            // GENRE CHIPS

            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: genres.length,
                itemBuilder: (context, index) {
                  final genre = genres[index];

                  final isSelected = selectedGenre == genre;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedGenre = genre;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFC8B6E2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        genre,
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF6B5B7B),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // BOOK LIST

            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFC8B6E2),
                ),
              )
                  : displayedBooks.isEmpty
                  ? const Center(
                child: Text(
                  'No books found 📖',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 16,
                    color: Color(0xFF9A8FA3),
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: displayedBooks.length,
                itemBuilder: (context, index) {
                  final book = displayedBooks[index];

                  // GET LOCAL COVER USING BOOK TITLE
                  final String localCover =
                  _getCoverImage(book['title']);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8DDF1),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        // BOOK COVER

                        Container(
                          height: 115,
                          width: 82,
                          decoration: BoxDecoration(
                            color:
                            Colors.white.withOpacity(0.55),
                            borderRadius:
                            BorderRadius.circular(15),
                          ),
                          child: localCover.isNotEmpty
                              ? ClipRRect(
                            borderRadius:
                            BorderRadius.circular(15),
                            child: Image.asset(
                              localCover,
                              fit: BoxFit.cover,
                              errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                  ) {
                                return const Center(
                                  child: Text(
                                    '📖',
                                    style: TextStyle(
                                      fontSize: 38,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                              : const Center(
                            child: Text(
                              '📖',
                              style: TextStyle(
                                fontSize: 38,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // BOOK DETAILS

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                book['title'],
                                maxLines: 2,
                                overflow:
                                TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily:
                                  'Times New Roman',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B5B7B),
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                book['author'],
                                style: const TextStyle(
                                  fontFamily:
                                  'Times New Roman',
                                  fontSize: 12,
                                  color: Color(0xFF8F8296),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                book['description'],
                                maxLines: 2,
                                overflow:
                                TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily:
                                  'Times New Roman',
                                  fontSize: 12,
                                  height: 1.35,
                                  color: Color(0xFF7D7183),
                                ),
                              ),

                              const SizedBox(height: 9),

                              SizedBox(
                                height: 34,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BookDetailsScreen(
                                              title:
                                              book['title'],
                                              author:
                                              book['author'],
                                              genre:
                                              book['genre'],
                                              subGenre:
                                              book['subGenre'],
                                              emoji: '📖',
                                              color:
                                              const Color(
                                                0xFFE8DDF1,
                                              ),
                                              personality:
                                              book[
                                              'personality'],
                                              description:
                                              book[
                                              'description'],
                                              coverImage:
                                              localCover,
                                              fileURL:
                                              book['fileURL'],
                                            ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton
                                      .styleFrom(
                                    backgroundColor:
                                    const Color(
                                      0xFFC8B6E2,
                                    ),
                                    foregroundColor:
                                    Colors.white,
                                    elevation: 0,
                                    padding:
                                    const EdgeInsets
                                        .symmetric(
                                      horizontal: 18,
                                    ),
                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius
                                          .circular(11),
                                    ),
                                  ),
                                  child: const Text(
                                    'Read Now',
                                    style: TextStyle(
                                      fontFamily:
                                      'Times New Roman',
                                      fontSize: 12,
                                      fontWeight:
                                      FontWeight.w600,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}