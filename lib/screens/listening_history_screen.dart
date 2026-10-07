import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'audiobook_screen.dart';

class ListeningHistoryScreen extends StatefulWidget {
  const ListeningHistoryScreen({
    super.key,
  });

  @override
  State<ListeningHistoryScreen> createState() =>
      _ListeningHistoryScreenState();
}

class _ListeningHistoryScreenState
    extends State<ListeningHistoryScreen> {
  bool isLoading = true;

  List<Map<String, dynamic>> listeningHistory = [];

  @override
  void initState() {
    super.initState();
    _loadListeningHistory();
  }

  // ============================================================
  // LOAD LISTENING HISTORY
  // ============================================================

  Future<void> _loadListeningHistory() async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance
          .collection('audiobook_history')
          .where(
        'userId',
        isEqualTo: user.uid,
      )
          .get();

      final List<Map<String, dynamic>> history = [];

      for (final QueryDocumentSnapshot<Map<String, dynamic>> document
      in snapshot.docs) {
        final Map<String, dynamic> data =
        Map<String, dynamic>.from(
          document.data(),
        );

        // --------------------------------------------------------
        // BOOK INFORMATION
        // --------------------------------------------------------

        final String title =
            data['title']?.toString() ?? '';

        String coverImage =
            data['coverImage']?.toString() ?? '';

        String description =
            data['description']?.toString() ?? '';

        String author =
            data['author']?.toString() ?? 'Book Author';

        String pdfPath =
            data['pdfPath']?.toString() ?? '';

        // --------------------------------------------------------
        // GET EXTRA INFORMATION FROM BOOKS COLLECTION
        // --------------------------------------------------------

        try {
          if (title.isNotEmpty) {
            final QuerySnapshot<Map<String, dynamic>>
            bookSnapshot =
            await FirebaseFirestore.instance
                .collection('books')
                .where(
              'title',
              isEqualTo: title,
            )
                .limit(1)
                .get();

            if (bookSnapshot.docs.isNotEmpty) {
              final Map<String, dynamic> bookData =
              bookSnapshot.docs.first.data();

              if (coverImage.isEmpty) {
                coverImage =
                    bookData['coverImage']
                        ?.toString() ??
                        '';
              }

              if (description.isEmpty) {
                description =
                    bookData['description']
                        ?.toString() ??
                        '';
              }

              if (author == 'Book Author') {
                author =
                    bookData['author']
                        ?.toString() ??
                        'Book Author';
              }

              if (pdfPath.isEmpty) {
                pdfPath =
                    bookData['fileURL']
                        ?.toString() ??
                        '';
              }
            }
          }
        } catch (e) {
          debugPrint(
            'Could not load extra book information: $e',
          );
        }

        data['coverImage'] = coverImage;
        data['description'] = description;
        data['author'] = author;
        data['pdfPath'] = pdfPath;

        history.add(data);
      }

      // --------------------------------------------------------
      // SORT BY LAST LISTENED
      // --------------------------------------------------------

      history.sort(
            (a, b) {
          final Timestamp? timeA =
          a['lastListenedAt'] is Timestamp
              ? a['lastListenedAt']
          as Timestamp
              : null;

          final Timestamp? timeB =
          b['lastListenedAt'] is Timestamp
              ? b['lastListenedAt']
          as Timestamp
              : null;

          if (timeA == null && timeB == null) {
            return 0;
          }

          if (timeA == null) {
            return 1;
          }

          if (timeB == null) {
            return -1;
          }

          return timeB.compareTo(timeA);
        },
      );

      if (!mounted) return;

      setState(() {
        listeningHistory = history;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Error loading listening history: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // COVER IMAGE FALLBACK
  // ============================================================

  String _getCoverImage(String title) {
    final String lowerTitle =
    title.toLowerCase();

    if (lowerTitle.contains(
      'hound of the baskervilles',
    )) {
      return 'assets/images/hound_of_the_baskervilles.jpg';
    }

    if (lowerTitle.contains(
      'adventure',
    ) &&
        lowerTitle.contains(
          'sherlock',
        )) {
      return 'assets/images/adventures_of_sherlock_holmes.jpg';
    }

    if (lowerTitle.contains(
      'great gatsby',
    )) {
      return 'assets/images/great_gatsby.jpg';
    }

    if (lowerTitle.contains(
      'pride and prejudice',
    )) {
      return 'assets/images/pride_and_prejudice.jpg';
    }

    if (lowerTitle.contains(
      'little women',
    )) {
      return 'assets/images/little_women.jpg';
    }

    if (lowerTitle.contains(
      'frankenstein',
    )) {
      return 'assets/images/frankenstein.jpg';
    }

    if (lowerTitle.contains(
      'dracula',
    )) {
      return 'assets/images/dracula.jpg';
    }

    if (lowerTitle.contains(
      'alice in wonderland',
    )) {
      return 'assets/images/alice_in_wonderland.jpg';
    }

    return '';
  }

  // ============================================================
  // LAST LISTENED TEXT
  // ============================================================

  String _formatLastListened(dynamic value) {
    if (value is! Timestamp) {
      return 'Recently listened';
    }

    final DateTime date =
    value.toDate();

    final DateTime now =
    DateTime.now();

    final Duration difference =
    now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  double _getProgress(
      Map<String, dynamic> data,
      ) {
    final dynamic savedProgress =
    data['progress'];

    if (savedProgress is num) {
      return savedProgress
          .toDouble()
          .clamp(0.0, 1.0);
    }

    final int current =
    data['currentChunk'] is num
        ? (data['currentChunk'] as num)
        .toInt()
        : 0;

    final int total =
    data['totalChunks'] is num
        ? (data['totalChunks'] as num)
        .toInt()
        : 0;

    if (total <= 0) {
      return 0.0;
    }

    return (current / total)
        .clamp(0.0, 1.0);
  }

  // ============================================================
  // OPEN AUDIOBOOK
  // ============================================================

  Future<void> _openAudiobook(
      Map<String, dynamic> data,
      ) async {
    final String title =
        data['title']?.toString() ?? '';

    final String pdfPath =
        data['pdfPath']?.toString() ?? '';

    if (title.isEmpty || pdfPath.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'This audiobook file could not be found.',
            style: TextStyle(
              fontFamily: 'Times New Roman',
            ),
          ),
        ),
      );

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudiobookScreen(
          title: title,
          pdfPath: pdfPath,
        ),
      ),
    );

    // Refresh progress when the user returns.
    await _loadListeningHistory();
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 80,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              height: 95,
              width: 95,
              decoration:
              const BoxDecoration(
                color: Color(0xFFE8DDF1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.headphones_rounded,
                size: 48,
                color: Color(0xFF8B739F),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Listening History Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start listening to a book and your audiobook history will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF9A8FA3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HISTORY CARD
  // ============================================================

  Widget _buildHistoryCard(
      Map<String, dynamic> data,
      ) {
    final String title =
        data['title']?.toString() ?? 'Untitled Book';

    final String author =
        data['author']?.toString() ?? 'Book Author';

    final String description =
        data['description']?.toString() ?? '';

    final String firestoreCover =
        data['coverImage']?.toString() ?? '';

    final String fallbackCover =
    _getCoverImage(title);

    final String cover =
    firestoreCover.isNotEmpty
        ? firestoreCover
        : fallbackCover;

    final double bookProgress =
    _getProgress(data);

    final bool completed =
        data['isCompleted'] == true;

    final int percentage =
    (bookProgress * 100).round();

    return Container(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8DDF1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.03),
            blurRadius: 8,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // COVER
              // --------------------------------------------------

              Container(
                width: 82,
                height: 112,
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFE8DDF1),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: cover.isNotEmpty
                    ? ClipRRect(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                  child:
                  Image.asset(
                    cover,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (
                        context,
                        error,
                        stackTrace,
                        ) {
                      return const Icon(
                        Icons
                            .menu_book_rounded,
                        size: 38,
                        color:
                        Color(0xFF8B739F),
                      );
                    },
                  ),
                )
                    : const Icon(
                  Icons
                      .headphones_rounded,
                  size: 38,
                  color:
                  Color(0xFF8B739F),
                ),
              ),

              const SizedBox(width: 14),

              // --------------------------------------------------
              // BOOK INFORMATION
              // --------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow:
                            TextOverflow.ellipsis,
                            style:
                            const TextStyle(
                              fontFamily:
                              'Times New Roman',
                              fontSize: 17,
                              fontWeight:
                              FontWeight.w700,
                              color:
                              Color(0xFF6B5B7B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (completed)
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              const Color(
                                0xFFDDEBDD,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                8,
                              ),
                            ),
                            child: const Text(
                              'DONE',
                              style:
                              TextStyle(
                                fontFamily:
                                'Times New Roman',
                                fontSize: 9,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                Color(
                                  0xFF587A58,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      author,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontFamily:
                        'Times New Roman',
                        fontSize: 12,
                        color:
                        Color(0xFF9A8FA3),
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (description.isNotEmpty)
                      Text(
                        description,
                        maxLines: 3,
                        overflow:
                        TextOverflow.ellipsis,
                        style:
                        const TextStyle(
                          fontFamily:
                          'Times New Roman',
                          fontSize: 12,
                          height: 1.3,
                          color:
                          Color(0xFF7D7087),
                        ),
                      ),

                    const SizedBox(height: 9),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .headphones_rounded,
                          size: 14,
                          color:
                          Color(0xFF8B739F),
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          '$percentage% listened',
                          style:
                          const TextStyle(
                            fontFamily:
                            'Times New Roman',
                            fontSize: 11,
                            fontWeight:
                            FontWeight.w600,
                            color:
                            Color(0xFF8B739F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // ------------------------------------------------------
          // PROGRESS BAR
          // ------------------------------------------------------

          ClipRRect(
            borderRadius:
            BorderRadius.circular(10),
            child:
            LinearProgressIndicator(
              value: bookProgress,
              minHeight: 5,
              backgroundColor:
              const Color(0xFFE8DDF1),
              valueColor:
              const AlwaysStoppedAnimation<
                  Color>(
                Color(0xFFC8B6E2),
              ),
            ),
          ),

          const SizedBox(height: 9),

          // ------------------------------------------------------
          // LAST LISTENED + CONTINUE
          // ------------------------------------------------------

          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Color(0xFF9A8FA3),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _formatLastListened(
                    data['lastListenedAt'],
                  ),
                  style:
                  const TextStyle(
                    fontFamily:
                    'Times New Roman',
                    fontSize: 11,
                    color:
                    Color(0xFF9A8FA3),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _openAudiobook(data),
                icon: Icon(
                  completed
                      ? Icons.replay_rounded
                      : Icons
                      .play_arrow_rounded,
                  size: 18,
                ),
                label: Text(
                  completed
                      ? 'Listen Again'
                      : 'Continue',
                  style:
                  const TextStyle(
                    fontFamily:
                    'Times New Roman',
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFFC8B6E2),
                  foregroundColor:
                  Colors.white,
                  elevation: 0,
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFFFF9FC),
      appBar: AppBar(
        backgroundColor:
        const Color(0xFFFFF9FC),
        elevation: 0,
        iconTheme:
        const IconThemeData(
          color: Color(0xFF6B5B7B),
        ),
        title: const Text(
          'Listening History 🎧',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            color: Color(0xFF6B5B7B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child:
        CircularProgressIndicator(
          color: Color(0xFFC8B6E2),
        ),
      )
          : listeningHistory.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        color:
        const Color(0xFF8B739F),
        onRefresh:
        _loadListeningHistory,
        child: ListView.builder(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),
          itemCount:
          listeningHistory.length,
          itemBuilder:
              (context, index) {
            return _buildHistoryCard(
              listeningHistory[index],
            );
          },
        ),
      ),
    );
  }
}