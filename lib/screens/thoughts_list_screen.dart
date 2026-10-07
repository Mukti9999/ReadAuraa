import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/thoughts_service.dart';
import 'thoughts_screen.dart';

class ThoughtsListScreen extends StatelessWidget {
  const ThoughtsListScreen({super.key});

  void _openThought(
      BuildContext context,
      String bookTitle,
      String thought,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF9FC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                color: Color(0xFF8B739F),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bookTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B5B7B),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              thought,
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF5E5368),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  color: Color(0xFF8B739F),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ThoughtsScreen(
                      bookTitle: bookTitle,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFFC8B6E2),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Edit',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Saved recently';
    }

    final DateTime date = timestamp.toDate();

    final String day =
    date.day.toString().padLeft(2, '0');
    final String month =
    date.month.toString().padLeft(2, '0');
    final String year =
    date.year.toString();

    return '$day/$month/$year';
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
          'My Thoughts 💭',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            color: Color(0xFF6B5B7B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: ThoughtsService.getThoughtsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFC8B6E2),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Text(
                  'Unable to load your thoughts right now.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 16,
                    color: Color(0xFF6B5B7B),
                  ),
                ),
              ),
            );
          }

          final docs =
              snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8DDF1),
                        borderRadius:
                        BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        size: 48,
                        color: Color(0xFF8B739F),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'No thoughts saved yet 💭',
                      style: TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B5B7B),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Your reading thoughts will appear here\nonce you save them.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF9A8FA3),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Sort newest first without requiring a
          // Firestore composite index.
          final sortedDocs = [...docs];

          sortedDocs.sort((a, b) {
            final Timestamp? dateA =
            a.data()['date'] as Timestamp?;
            final Timestamp? dateB =
            b.data()['date'] as Timestamp?;

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

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              18,
              15,
              18,
              30,
            ),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final data =
              sortedDocs[index].data();

              final String bookTitle =
                  data['bookTitle']?.toString() ??
                      'Unknown Book';

              final String thought =
                  data['thoughts']?.toString() ??
                      '';

              final Timestamp? date =
              data['date'] as Timestamp?;

              return GestureDetector(
                onTap: () {
                  _openThought(
                    context,
                    bookTitle,
                    thought,
                  );
                },
                child: Container(
                  margin:
                  const EdgeInsets.only(bottom: 14),
                  padding:
                  const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(20),
                    border: Border.all(
                      color:
                      const Color(0xFFE8DDF1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                        Colors.black.withOpacity(
                          0.03,
                        ),
                        blurRadius: 10,
                        offset:
                        const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color:
                              const Color(
                                0xFFE8DDF1,
                              ),
                              borderRadius:
                              BorderRadius.circular(
                                12,
                              ),
                            ),
                            child: const Icon(
                              Icons
                                  .menu_book_rounded,
                              color:
                              Color(0xFF8B739F),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  bookTitle,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow
                                      .ellipsis,
                                  style:
                                  const TextStyle(
                                    fontFamily:
                                    'Times New Roman',
                                    fontSize: 17,
                                    fontWeight:
                                    FontWeight.w700,
                                    color:
                                    Color(
                                      0xFF6B5B7B,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  _formatDate(date),
                                  style:
                                  const TextStyle(
                                    fontFamily:
                                    'Times New Roman',
                                    fontSize: 12,
                                    color:
                                    Color(
                                      0xFFAAA0AE,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Icon(
                            Icons
                                .arrow_forward_ios_rounded,
                            size: 16,
                            color:
                            Color(0xFFB5AAB9),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Text(
                        thought,
                        maxLines: 4,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily:
                          'Times New Roman',
                          fontSize: 15,
                          height: 1.5,
                          color:
                          Color(0xFF5E5368),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Tap to read full thought',
                        style: TextStyle(
                          fontFamily:
                          'Times New Roman',
                          fontSize: 12,
                          color:
                          Color(0xFF8B739F),
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}