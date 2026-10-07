import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'thoughts_screen.dart';
import 'favourites_screen.dart';
import 'ai_reflection_screen.dart';
import 'music_screen.dart';

import '../services/favourite_service.dart';
import '../services/reading_progress_service.dart';

class PdfReaderScreen extends StatefulWidget {
  final String title;
  final String pdfPath;

  const PdfReaderScreen({
    super.key,
    required this.title,
    required this.pdfPath,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final PdfViewerController _pdfController =
  PdfViewerController();

  int currentPage = 1;
  int totalPages = 0;

  bool readingMode = false;
  bool viewerReady = false;

  @override
  void initState() {
    super.initState();

    currentPage =
        ReadingProgressService.getProgress(widget.title);
  }

  // --------------------------------------------------
  // SAVE READING HISTORY TO FIREBASE
  // --------------------------------------------------

  Future<void> _saveReadingHistory() async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      final String progress = totalPages > 0
          ? 'Page $currentPage of $totalPages'
          : 'Page $currentPage';

      await FirebaseFirestore.instance
          .collection('reading_history')
          .doc('${user.uid}_${widget.title}')
          .set(
        {
          'userId': user.uid,
          'title': widget.title,
          'author': 'Book Author',
          'progress': progress,
          'currentPage': currentPage,
          'totalPages': totalPages,
          'personality': 'Reading Journey',
          'lastRead': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint(
        'Reading history error: $e',
      );
    }
  }

  // --------------------------------------------------
  // PDF READY
  // --------------------------------------------------

  void onViewerReady(
      PdfDocument document,
      PdfViewerController controller,
      ) {
    setState(() {
      viewerReady = true;
      totalPages = document.pages.length;
    });

    if (currentPage > 1 &&
        currentPage <= document.pages.length) {
      controller.goToPage(
        pageNumber: currentPage,
      );
    }

    _saveReadingHistory();
  }

  // --------------------------------------------------
  // PAGE CHANGED
  // --------------------------------------------------

  void onPageChanged(int? pageNumber) {
    if (pageNumber == null) return;

    setState(() {
      currentPage = pageNumber;
    });

    ReadingProgressService.saveProgress(
      bookTitle: widget.title,
      currentPage: pageNumber,
    );

    _saveReadingHistory();
  }

  // --------------------------------------------------
  // PREVIOUS PAGE
  // --------------------------------------------------

  Future<void> goToPreviousPage() async {
    if (!viewerReady) return;

    if (currentPage > 1) {
      await _pdfController.goToPage(
        pageNumber: currentPage - 1,
      );
    }
  }

  // --------------------------------------------------
  // NEXT PAGE
  // --------------------------------------------------

  Future<void> goToNextPage() async {
    if (!viewerReady) return;

    if (currentPage < totalPages) {
      await _pdfController.goToPage(
        pageNumber: currentPage + 1,
      );
    }
  }

  // --------------------------------------------------
  // OPEN MUSIC SCREEN
  // --------------------------------------------------

  void openMusic() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MusicScreen(),
      ),
    );
  }

  // --------------------------------------------------
  // THOUGHTS
  // --------------------------------------------------

  void openThoughts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThoughtsScreen(
          bookTitle: widget.title,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // AI REFLECTION
  // --------------------------------------------------

  void openAIReflection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIReflectionScreen(
          bookTitle: widget.title,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // FAVOURITE PASSAGE
  // --------------------------------------------------

  void addFavouritePassage() {
    final TextEditingController passageController =
    TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Save Favourite Passage 💗',
            style: TextStyle(
              fontFamily: 'Times New Roman',
              color: Color(0xFF6B5B7B),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: passageController,
            maxLines: 5,
            style: const TextStyle(
              fontFamily: 'Times New Roman',
            ),
            decoration: InputDecoration(
              hintText:
              'Paste or type the line you want to save...',
              hintStyle: const TextStyle(
                fontFamily: 'Times New Roman',
              ),
              filled: true,
              fillColor: const Color(0xFFFFF9FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
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
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final String passage =
                passageController.text.trim();

                if (passage.isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a passage first.',
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                        ),
                      ),
                    ),
                  );

                  return;
                }

                final FavouritePassageResult result =
                await FavouriteService.addFavourite(
                  title: widget.title,
                  author: 'Book Author',
                  type: 'Favourite Line',
                  content: passage,
                );

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext);

                if (!mounted) return;

                String message;

                switch (result) {
                  case FavouritePassageResult.added:
                    message =
                    'Passage saved to favourites ❤️';
                    break;

                  case FavouritePassageResult.alreadyExists:
                    message =
                    'This passage is already in your favourites ❤️';
                    break;

                  case FavouritePassageResult.notLoggedIn:
                    message =
                    'Please login to save favourite passages.';
                    break;

                  case FavouritePassageResult.error:
                    message =
                    'Could not save the passage. Please try again.';
                    break;
                }

                ScaffoldMessenger.of(context)
                    .showSnackBar(
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
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFFC8B6E2),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Save',
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

  // --------------------------------------------------
  // NIGHT MODE PDF FILTER
  // --------------------------------------------------

  Widget _buildPdfViewer() {
    final Widget pdfViewer = PdfViewer.asset(
      widget.pdfPath,
      controller: _pdfController,
      initialPageNumber: currentPage,
      params: PdfViewerParams(
        // ------------------------------------------------
        // TEXT SELECTION ENABLED
        // ------------------------------------------------
        textSelectionParams: PdfTextSelectionParams(
          enabled: true,
        ),

        backgroundColor: readingMode
            ? const Color(0xFF1E1B22)
            : const Color(0xFFEAE6EC),

        onViewerReady: onViewerReady,
        onPageChanged: onPageChanged,
      ),
    );

    if (!readingMode) {
      return pdfViewer;
    }

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(
        <double>[
          -1,
          0,
          0,
          0,
          255,
          0,
          -1,
          0,
          0,
          255,
          0,
          0,
          -1,
          0,
          255,
          0,
          0,
          0,
          1,
          0,
        ],
      ),
      child: pdfViewer,
    );
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = readingMode
        ? const Color(0xFF1E1B22)
        : const Color(0xFFFFF9FC);

    return Scaffold(
      backgroundColor: backgroundColor,

      // ------------------------------------------------
      // APP BAR
      // ------------------------------------------------

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: readingMode
                ? Colors.white
                : const Color(0xFF6B5B7B),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Times New Roman',
            color: readingMode
                ? Colors.white
                : const Color(0xFF6B5B7B),
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          // FAVOURITE
          IconButton(
            tooltip: 'Favourite Passage',
            icon: Icon(
              Icons.favorite_border_rounded,
              color: readingMode
                  ? Colors.white
                  : const Color(0xFF6B5B7B),
            ),
            onPressed: addFavouritePassage,
          ),

          // MUSIC
          IconButton(
            tooltip: 'Reading Music',
            icon: Icon(
              Icons.music_note_rounded,
              color: readingMode
                  ? Colors.white
                  : const Color(0xFF6B5B7B),
            ),
            onPressed: openMusic,
          ),

          // NIGHT MODE
          IconButton(
            tooltip: readingMode
                ? 'Light Reading'
                : 'Night Reading',
            icon: Icon(
              readingMode
                  ? Icons.light_mode_rounded
                  : Icons.nightlight_round,
              color: readingMode
                  ? Colors.white
                  : const Color(0xFF6B5B7B),
            ),
            onPressed: () {
              setState(() {
                readingMode = !readingMode;
              });
            },
          ),
        ],
      ),

      // ------------------------------------------------
      // BODY
      // ------------------------------------------------

      body: Column(
        children: [
          // PAGE INDICATOR
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 9,
            ),
            color: readingMode
                ? const Color(0xFF2A2630)
                : const Color(0xFFF0EAF6),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: readingMode
                      ? const Color(0xFFE8DDF1)
                      : const Color(0xFF8B739F),
                ),

                const SizedBox(width: 7),

                Text(
                  totalPages == 0
                      ? 'Page $currentPage'
                      : 'Page $currentPage of $totalPages',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: readingMode
                        ? const Color(0xFFE8DDF1)
                        : const Color(0xFF6B5B7B),
                  ),
                ),
              ],
            ),
          ),

          // REAL PDF
          Expanded(
            child: _buildPdfViewer(),
          ),
        ],
      ),

      // ------------------------------------------------
      // BOTTOM READING CONTROLS
      // ------------------------------------------------

      bottomNavigationBar:
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            12,
            10,
            12,
            12,
          ),
          decoration: BoxDecoration(
            color: readingMode
                ? const Color(0xFF242129)
                : Colors.white,
            boxShadow: [
              BoxShadow(
                color:
                Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset:
                const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              // ------------------------------------------
              // PREVIOUS / NEXT
              // ------------------------------------------

              Row(
                children: [
                  Expanded(
                    child:
                    OutlinedButton.icon(
                      onPressed:
                      viewerReady &&
                          currentPage > 1
                          ? goToPreviousPage
                          : null,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Previous',
                        style: TextStyle(
                          fontFamily:
                          'Times New Roman',
                        ),
                      ),
                      style:
                      OutlinedButton.styleFrom(
                        foregroundColor:
                        const Color(
                          0xFF6B5B7B,
                        ),
                        side:
                        const BorderSide(
                          color: Color(
                            0xFFC8B6E2,
                          ),
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            13,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                    ElevatedButton.icon(
                      onPressed:
                      viewerReady &&
                          currentPage <
                              totalPages
                          ? goToNextPage
                          : null,
                      icon: const Icon(
                        Icons
                            .arrow_forward_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Next',
                        style: TextStyle(
                          fontFamily:
                          'Times New Roman',
                        ),
                      ),
                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(
                          0xFFC8B6E2,
                        ),
                        foregroundColor:
                        Colors.white,
                        elevation: 0,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ------------------------------------------
              // THOUGHTS / AI
              // ------------------------------------------

              Row(
                children: [
                  Expanded(
                    child:
                    OutlinedButton.icon(
                      onPressed:
                      openThoughts,
                      icon: const Icon(
                        Icons
                            .edit_note_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'My Thoughts',
                        style: TextStyle(
                          fontFamily:
                          'Times New Roman',
                        ),
                      ),
                      style:
                      OutlinedButton.styleFrom(
                        foregroundColor:
                        const Color(
                          0xFF6B5B7B,
                        ),
                        side:
                        const BorderSide(
                          color: Color(
                            0xFFD8CCE4,
                          ),
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            13,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                    OutlinedButton.icon(
                      onPressed:
                      openAIReflection,
                      icon: const Icon(
                        Icons
                            .auto_awesome_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'AI Reflection',
                        style: TextStyle(
                          fontFamily:
                          'Times New Roman',
                        ),
                      ),
                      style:
                      OutlinedButton.styleFrom(
                        foregroundColor:
                        const Color(
                          0xFF6B5B7B,
                        ),
                        side:
                        const BorderSide(
                          color: Color(
                            0xFFD8CCE4,
                          ),
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ------------------------------------------
              // MUSIC
              // ------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 44,
                child:
                ElevatedButton.icon(
                  onPressed: openMusic,
                  icon: const Icon(
                    Icons.music_note_rounded,
                    size: 21,
                  ),
                  label: const Text(
                    'Choose Reading Music 🎵',
                    style: TextStyle(
                      fontFamily:
                      'Times New Roman',
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(
                      0xFFE8DDF1,
                    ),
                    foregroundColor:
                    const Color(
                      0xFF6B5B7B,
                    ),
                    elevation: 0,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius
                          .circular(
                        13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}