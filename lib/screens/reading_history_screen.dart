import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/reading_history_service.dart';

class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen> {
  List<Map<String, String>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReadingHistory();
  }

  Future<void> _loadReadingHistory() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          _history = ReadingHistoryService.getHistory();
          _isLoading = false;
        });
        return;
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance
          .collection('reading_history')
          .where('userId', isEqualTo: user.uid)
          .get();

      final List<Map<String, String>> firebaseHistory = snapshot.docs.map(
            (document) {
          final data = document.data();

          return {
            'title': data['title']?.toString() ?? 'Unknown Book',
            'author': data['author']?.toString() ?? 'Unknown Author',
            'progress': data['progress']?.toString() ?? '0%',
            'personality':
            data['personality']?.toString() ?? 'Reading Journey',
          };
        },
      ).toList();

      if (mounted) {
        setState(() {
          _history = firebaseHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If Firebase history is not available yet,
      // show the existing local reading history.
      if (mounted) {
        setState(() {
          _history = ReadingHistoryService.getHistory();
          _isLoading = false;
        });
      }
    }
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
        title: const Text(
          'Reading History 📖',
          style: TextStyle(
            color: Color(0xFF6B5B7B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Reading Journey ✨',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Keep track of the stories you have explored.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9A8FA3),
              ),
            ),

            const SizedBox(height: 25),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 70),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFC8B6E2),
                  ),
                ),
              )
            else if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 70),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 55,
                        color: Color(0xFFC8B6E2),
                      ),
                      SizedBox(height: 15),
                      Text(
                        'No Reading History Yet 📖',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B5B7B),
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Open a book and start reading to see it here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9A8FA3),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._history.map(
                    (book) => _historyCard(
                  title: book['title'] ?? 'Unknown Book',
                  author: book['author'] ?? 'Unknown Author',
                  progress: book['progress'] ?? '0%',
                  personality:
                  book['personality'] ?? 'Reading Journey',
                ),
              ),

            const SizedBox(height: 15),

            const Center(
              child: Text(
                'More reading activity will appear here 📚',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFAAA0B2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyCard({
    required String title,
    required String author,
    required String progress,
    required String personality,
  }) {
    Color cardColor;

    if (personality == 'Romance') {
      cardColor = const Color(0xFFF7DDE7);
    } else {
      cardColor = const Color(0xFFE8DDF1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 82,
            width: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Center(
              child: Icon(
                Icons.menu_book_rounded,
                size: 30,
                color: Color(0xFF8B739F),
              ),
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B5B7B),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  author,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8F8296),
                  ),
                ),

                const SizedBox(height: 9),

                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: Color(0xFF8B739F),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      personality,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8B739F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  progress,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9A8FA3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}