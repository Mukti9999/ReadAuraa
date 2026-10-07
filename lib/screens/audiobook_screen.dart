import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/pdf_text_service.dart';
import '../services/speech_bridge.dart';

class AudiobookScreen extends StatefulWidget {
  final String title;
  final String pdfPath;

  const AudiobookScreen({
    super.key,
    required this.title,
    required this.pdfPath,
  });

  @override
  State<AudiobookScreen> createState() => _AudiobookScreenState();
}

class _AudiobookScreenState extends State<AudiobookScreen>
    with TickerProviderStateMixin {
  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = true;

  String extractedText = '';

  double voiceSpeed = 1.0;
  double volume = 1.0;

  bool isPlaying = false;
  bool isPaused = false;

  bool expressiveReading = true;

  late AnimationController waveController;

  // ============================================================
  // AUDIOBOOK DATA
  // ============================================================

  List<String> speechChunks = [];

  int currentChunkIndex = 0;

  int speechSession = 0;

  // ============================================================
  // FIRESTORE SAVE STATE
  // ============================================================

  bool isSavingProgress = false;

  // ============================================================
  // ESTIMATED AUDIO POSITION
  // ============================================================

  int get totalCharacters {
    return speechChunks.fold(
      0,
          (sum, chunk) => sum + chunk.length,
    );
  }

  int get currentCharacters {
    if (speechChunks.isEmpty) {
      return 0;
    }

    int characters = 0;

    final int safeIndex = currentChunkIndex.clamp(
      0,
      speechChunks.length,
    );

    for (int i = 0; i < safeIndex; i++) {
      characters += speechChunks[i].length;
    }

    return characters;
  }

  double get progress {
    if (speechChunks.isEmpty) {
      return 0;
    }

    return (currentChunkIndex / speechChunks.length)
        .clamp(0.0, 1.0);
  }

  // Approximate audiobook duration.
  //
  // Browser speech synthesis does not expose exact duration.

  double get estimatedTotalSeconds {
    if (totalCharacters == 0) {
      return 0;
    }

    const double averageCharactersPerSecond = 14.0;

    return totalCharacters /
        averageCharactersPerSecond /
        voiceSpeed;
  }

  double get estimatedCurrentSeconds {
    if (currentCharacters == 0) {
      return 0;
    }

    const double averageCharactersPerSecond = 14.0;

    return currentCharacters /
        averageCharactersPerSecond /
        voiceSpeed;
  }

  // ============================================================
  // FIRESTORE DOCUMENT ID
  // ============================================================

  String get audiobookDocumentId {
    final String safeTitle = widget.title
        .trim()
        .replaceAll(
      RegExp(r'[/\\#?]'),
      '_',
    );

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return safeTitle;
    }

    return '${user.uid}_$safeTitle';
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    waveController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    );

    extractBookText();
  }

  // ============================================================
  // EXTRACT PDF TEXT
  // ============================================================

  Future<void> extractBookText() async {
    try {
      final String text =
      await PdfTextService.extractTextFromAsset(
        widget.pdfPath,
      );

      debugPrint(
        '====================================',
      );

      debugPrint(
        'READAURA AUDIOBOOK TEXT',
      );

      debugPrint(
        'Total characters: ${text.length}',
      );

      debugPrint(
        '====================================',
      );

      if (text.isNotEmpty) {
        final int previewLength =
        text.length > 15000
            ? 15000
            : text.length;

        debugPrint(
          text.substring(
            0,
            previewLength,
          ),
        );
      }

      debugPrint(
        '====================================',
      );

      if (!mounted) return;

      setState(() {
        extractedText = text;
        isLoading = false;
      });

      if (text.trim().isEmpty) {
        return;
      }

      // Create audiobook sections.
      createSpeechChunks(text);

      // Restore previously saved listening position.
      await _loadSavedAudiobookProgress();
    } catch (e) {
      debugPrint(
        'READAURA PDF EXTRACTION ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        extractedText = '';
      });

      showMessage(
        'Could not read PDF: $e',
      );
    }
  }

  // ============================================================
  // CREATE SPEECH CHUNKS
  // ============================================================

  void createSpeechChunks(String text) {
    final String cleanedText = text
        .replaceAll(
      '\r\n',
      '\n',
    )
        .replaceAll(
      '\r',
      '\n',
    )
        .replaceAll(
      RegExp(r'[ \t]+'),
      ' ',
    )
        .replaceAll(
      RegExp(r'\n{3,}'),
      '\n\n',
    )
        .trim();

    if (cleanedText.isEmpty) {
      return;
    }

    /*
      Smaller natural speech sections.

      This helps with:

      • smoother playback
      • better seeking
      • better pause/resume
      • expressive voice changes
      • Firestore progress tracking
    */

    final RegExp sentenceRegex = RegExp(
      r'[^.!?]+[.!?]+|[^.!?]+$',
      multiLine: true,
    );

    final List<String> sentences = sentenceRegex
        .allMatches(cleanedText)
        .map(
          (match) =>
      match.group(0)?.trim() ?? '',
    )
        .where(
          (sentence) =>
      sentence.isNotEmpty,
    )
        .toList();

    final List<String> chunks = [];

    String currentChunk = '';

    for (final String sentence in sentences) {
      if (sentence.isEmpty) {
        continue;
      }

      if (currentChunk.isEmpty) {
        currentChunk = sentence;
      } else if (
      currentChunk.length +
          sentence.length <
          350) {
        currentChunk =
        '$currentChunk $sentence';
      } else {
        chunks.add(
          currentChunk.trim(),
        );

        currentChunk = sentence;
      }
    }

    if (currentChunk.trim().isNotEmpty) {
      chunks.add(
        currentChunk.trim(),
      );
    }

    speechChunks = chunks;

    debugPrint(
      '====================================',
    );

    debugPrint(
      'READAURA SPEECH CHUNKS',
    );

    debugPrint(
      'Total chunks: ${speechChunks.length}',
    );

    debugPrint(
      '====================================',
    );
  }

  // ============================================================
  // LOAD SAVED AUDIOBOOK PROGRESS
  // ============================================================

  Future<void> _loadSavedAudiobookProgress() async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      if (speechChunks.isEmpty) {
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>>
      document =
      await FirebaseFirestore.instance
          .collection('audiobook_history')
          .doc(audiobookDocumentId)
          .get();

      if (!document.exists) {
        debugPrint(
          'No previous audiobook position found.',
        );

        return;
      }

      final Map<String, dynamic> data =
          document.data() ?? {};

      final bool isCompleted =
          data['isCompleted'] == true;

      int savedChunk = 0;

      if (data['currentChunk'] is int) {
        savedChunk =
        data['currentChunk'] as int;
      } else {
        savedChunk = int.tryParse(
          data['currentChunk']
              ?.toString() ??
              '',
        ) ??
            0;
      }

      savedChunk = savedChunk.clamp(
        0,
        speechChunks.length,
      );

      // If the previous session was completed,
      // keep the audiobook ready to start again
      // from the beginning.

      if (isCompleted ||
          savedChunk >= speechChunks.length) {
        savedChunk = 0;
      }

      if (!mounted) return;

      setState(() {
        currentChunkIndex = savedChunk;
      });

      debugPrint(
        '====================================',
      );

      debugPrint(
        'READAURA RESTORED AUDIOBOOK POSITION',
      );

      debugPrint(
        'Book: ${widget.title}',
      );

      debugPrint(
        'Chunk: $currentChunkIndex '
            '/ ${speechChunks.length}',
      );

      debugPrint(
        'Progress: '
            '${(progress * 100).round()}%',
      );

      debugPrint(
        '====================================',
      );
    } catch (e) {
      debugPrint(
        'Error loading audiobook progress: $e',
      );
    }
  }

  // ============================================================
  // SAVE AUDIOBOOK PROGRESS TO FIREBASE
  // ============================================================

  Future<void> _saveAudiobookProgress({
    bool completed = false,
  }) async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      if (speechChunks.isEmpty) {
        return;
      }

      if (isSavingProgress) {
        return;
      }

      isSavingProgress = true;

      int safeChunk = currentChunkIndex.clamp(
        0,
        speechChunks.length,
      );

      double savedProgress;

      if (completed) {
        safeChunk = speechChunks.length;
        savedProgress = 1.0;
      } else {
        savedProgress =
            (safeChunk / speechChunks.length)
                .clamp(0.0, 1.0);
      }

      await FirebaseFirestore.instance
          .collection('audiobook_history')
          .doc(audiobookDocumentId)
          .set(
        {
          'userId': user.uid,

          'title': widget.title,

          'pdfPath': widget.pdfPath,

          'currentChunk': safeChunk,

          'totalChunks': speechChunks.length,

          'progress': savedProgress,

          'isCompleted': completed,

          'lastListenedAt':
          FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      debugPrint(
        '====================================',
      );

      debugPrint(
        'READAURA AUDIOBOOK PROGRESS SAVED',
      );

      debugPrint(
        'Book: ${widget.title}',
      );

      debugPrint(
        'Chunk: $safeChunk '
            '/ ${speechChunks.length}',
      );

      debugPrint(
        'Progress: '
            '${(savedProgress * 100).round()}%',
      );

      debugPrint(
        'Completed: $completed',
      );

      debugPrint(
        '====================================',
      );
    } catch (e) {
      debugPrint(
        'Error saving audiobook progress: $e',
      );
    } finally {
      isSavingProgress = false;
    }
  }

  // ============================================================
  // EXPRESSIVE READING
  // ============================================================

  double getChunkPitch(String text) {
    if (!expressiveReading) {
      return 1.0;
    }

    final String lower =
    text.toLowerCase();

    if (lower.contains('!')) {
      return 1.04;
    }

    if (lower.contains('?')) {
      return 1.02;
    }

    if (lower.contains(
      RegExp(
        r'\b(whispered|whisper|murmured|quietly|softly)\b',
      ),
    )) {
      return 0.95;
    }

    if (lower.contains(
      RegExp(
        r'\b(shouted|shout|screamed|scream|yelled|yell)\b',
      ),
    )) {
      return 1.07;
    }

    if (lower.contains(
      RegExp(
        r'\b(laughed|laugh|excited|excitedly)\b',
      ),
    )) {
      return 1.05;
    }

    if (lower.contains(
      RegExp(
        r'\b(cried|crying|sadly|sad|tears|wept|weeping)\b',
      ),
    )) {
      return 0.96;
    }

    return 1.0;
  }

  // ============================================================
  // EXPRESSIVE READING SPEED
  // ============================================================

  double getChunkRate(String text) {
    if (!expressiveReading) {
      return voiceSpeed;
    }

    final String lower =
    text.toLowerCase();

    double rate = voiceSpeed;

    if (lower.contains('...')) {
      rate *= 0.90;
    }

    if (lower.contains('!')) {
      rate *= 1.02;
    }

    if (lower.contains('?')) {
      rate *= 0.97;
    }

    if (lower.contains(
      RegExp(
        r'\b(suddenly|slowly|silently|quietly|softly)\b',
      ),
    )) {
      rate *= 0.94;
    }

    return rate.clamp(
      0.5,
      2.0,
    );
  }

  // ============================================================
  // PLAY FULL BOOK
  // ============================================================

  Future<void> playFullBook({
    int startChunk = 0,
  }) async {
    if (speechChunks.isEmpty) {
      showMessage(
        'No readable audiobook text found.',
      );

      return;
    }

    speechSession++;

    final int currentSession =
        speechSession;

    readAuraStop();

    int safeStartChunk =
    startChunk.clamp(
      0,
      speechChunks.length,
    );

    // If the audiobook has reached the end,
    // pressing Play again starts from the beginning.

    if (safeStartChunk >=
        speechChunks.length) {
      safeStartChunk = 0;
    }

    currentChunkIndex =
        safeStartChunk;

    // Save that audiobook has been started again.
    await _saveAudiobookProgress(
      completed: false,
    );

    if (!mounted) return;

    setState(() {
      isPlaying = true;
      isPaused = false;
    });

    waveController.repeat();

    /*
      Continuous audiobook playback.

      Each speech section is spoken one after another.
    */

    while (
    currentChunkIndex <
        speechChunks.length &&
        currentSession ==
            speechSession) {
      if (!mounted) return;

      final String chunk =
      speechChunks[
      currentChunkIndex
      ].trim();

      if (chunk.isEmpty) {
        currentChunkIndex++;

        await _saveAudiobookProgress();

        continue;
      }

      final double pitch =
      getChunkPitch(chunk);

      final double rate =
      getChunkRate(chunk);

      debugPrint(
        '====================================',
      );

      debugPrint(
        'READAURA AUDIOBOOK',
      );

      debugPrint(
        'Section: $currentChunkIndex / '
            '${speechChunks.length}',
      );

      debugPrint(
        'Pitch: $pitch',
      );

      debugPrint(
        'Rate: $rate',
      );

      debugPrint(
        '====================================',
      );

      try {
        await readAuraSpeak(
          chunk,
          rate,
          pitch,
          volume,
        );
      } catch (e) {
        debugPrint(
          'Speech chunk error: $e',
        );

        if (currentSession !=
            speechSession) {
          return;
        }

        break;
      }

      if (currentSession !=
          speechSession) {
        return;
      }

      if (!mounted) return;

      // The current chunk has finished.
      currentChunkIndex++;

      setState(() {});

      // --------------------------------------------------------
      // SAVE AFTER EVERY CHUNK
      // --------------------------------------------------------

      final bool completed =
          currentChunkIndex >=
              speechChunks.length;

      await _saveAudiobookProgress(
        completed: completed,
      );
    }

    if (!mounted) return;

    if (currentSession ==
        speechSession) {
      final bool completed =
          currentChunkIndex >=
              speechChunks.length;

      setState(() {
        isPlaying = false;
        isPaused = false;
      });

      waveController.stop();

      if (completed) {
        // Keep the completed position saved in Firebase.

        await _saveAudiobookProgress(
          completed: true,
        );

        // Reset locally so pressing Play again
        // starts the book from the beginning.

        if (mounted) {
          setState(() {
            currentChunkIndex = 0;
          });
        }
      }
    }
  }

  // ============================================================
  // PLAY / PAUSE
  // ============================================================

  void togglePlayPause() {
    if (isPlaying) {
      if (isPaused) {
        resumeAudiobook();
      } else {
        pauseAudiobook();
      }
    } else {
      final int start =
      currentChunkIndex >=
          speechChunks.length
          ? 0
          : currentChunkIndex;

      playFullBook(
        startChunk: start,
      );
    }
  }

  // ============================================================
  // PAUSE
  // ============================================================

  void pauseAudiobook() {
    if (!isPlaying) {
      return;
    }

    readAuraPause();

    // Save the current chunk immediately.
    _saveAudiobookProgress();

    if (!mounted) return;

    setState(() {
      isPaused = true;
    });

    waveController.stop();
  }

  // ============================================================
  // RESUME
  // ============================================================

  void resumeAudiobook() {
    if (!isPlaying) {
      return;
    }

    readAuraResume();

    if (!mounted) return;

    setState(() {
      isPaused = false;
    });

    waveController.repeat();

    _saveAudiobookProgress();
  }

  // ============================================================
  // STOP
  // ============================================================

  void stopAudiobook() {
    // Save BEFORE changing the playback session.
    _saveAudiobookProgress();

    speechSession++;

    readAuraStop();

    if (!mounted) return;

    setState(() {
      isPlaying = false;
      isPaused = false;
    });

    waveController.stop();
  }

  // ============================================================
  // 10 SECOND BACK
  // ============================================================

  void seekBackward10Seconds() {
    if (speechChunks.isEmpty) {
      return;
    }

    /*
      Browser speech synthesis does not expose
      exact milliseconds of the current spoken sentence.

      Therefore we estimate the number of audiobook
      sections representing approximately 10 seconds.
    */

    final int sectionsToMove =
    _estimatedSectionsForTenSeconds();

    final int target =
        currentChunkIndex -
            sectionsToMove;

    _seekToChunk(
      target.clamp(
        0,
        speechChunks.length - 1,
      ),
    );
  }

  // ============================================================
  // 10 SECOND FORWARD
  // ============================================================

  void seekForward10Seconds() {
    if (speechChunks.isEmpty) {
      return;
    }

    final int sectionsToMove =
    _estimatedSectionsForTenSeconds();

    final int target =
        currentChunkIndex +
            sectionsToMove;

    _seekToChunk(
      target.clamp(
        0,
        speechChunks.length - 1,
      ),
    );
  }

  // ============================================================
  // ESTIMATE 10 SECOND SECTIONS
  // ============================================================

  int _estimatedSectionsForTenSeconds() {
    if (speechChunks.isEmpty) {
      return 1;
    }

    final double averageChunkLength =
        totalCharacters /
            speechChunks.length;

    if (averageChunkLength <= 0) {
      return 1;
    }

    final double charactersPerTenSeconds =
        140.0 * voiceSpeed;

    final int sections =
    (charactersPerTenSeconds /
        averageChunkLength)
        .round();

    return sections.clamp(
      1,
      5,
    );
  }

  // ============================================================
  // SEEK TO CHUNK
  // ============================================================

  void _seekToChunk(
      int targetChunk,
      ) {
    currentChunkIndex =
        targetChunk.clamp(
          0,
          speechChunks.length - 1,
        );

    // Save the new position immediately.
    _saveAudiobookProgress();

    /*
      If audio is currently playing,
      restart speech from the new position.
    */

    if (isPlaying) {
      playFullBook(
        startChunk: currentChunkIndex,
      );
    } else {
      setState(() {});
    }
  }

  // ============================================================
  // CHANGE SPEED
  // ============================================================

  void changeSpeed(
      double value,
      ) {
    setState(() {
      voiceSpeed = value;
    });

    /*
      Restart from the current audiobook position
      so the new speed takes effect immediately.
    */

    if (isPlaying && !isPaused) {
      final int resumeChunk =
          currentChunkIndex;

      playFullBook(
        startChunk: resumeChunk,
      );
    }
  }

  // ============================================================
  // CHANGE VOLUME
  // ============================================================

  void changeVolume(
      double value,
      ) {
    setState(() {
      volume = value;
    });

    /*
      Volume is passed to the browser speech engine
      when the next speech section begins.
    */
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String formatDuration(
      double seconds,
      ) {
    final int total =
    seconds.round();

    final int minutes =
        total ~/ 60;

    final int remainingSeconds =
        total % 60;

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily:
            'Times New Roman',
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WAVEFORM
  // ============================================================

  Widget buildWaveform() {
    return AnimatedBuilder(
      animation: waveController,
      builder: (
          context,
          child,
          ) {
        final double animationValue =
            waveController.value;

        return Row(
          mainAxisSize:
          MainAxisSize.min,
          children:
          List.generate(
            12,
                (index) {
              final double phase =
                  (animationValue +
                      index * 0.08) %
                      1.0;

              final double height =
                  8 +
                      (phase < 0.5
                          ? phase * 32
                          : (1 - phase) * 32);

              return Container(
                width: 3,
                height: height,
                margin:
                const EdgeInsets
                    .symmetric(
                  horizontal: 2,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFF8B739F,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    5,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // CURRENT AUDIO CARD
  // ============================================================

  Widget buildCurrentAudioCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(20),
      decoration:
      BoxDecoration(
        gradient:
        const LinearGradient(
          colors: [
            Color(0xFFF4ECFA),
            Color(0xFFFFF3F8),
          ],
        ),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border:
        Border.all(
          color:
          const Color(
            0xFFE8DDF1,
          ),
        ),
      ),
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
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
                      .headphones_rounded,
                  color:
                  Color(
                    0xFF8B739F,
                  ),
                  size: 25,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    const Text(
                      'NOW LISTENING',
                      style:
                      TextStyle(
                        fontFamily:
                        'Times New Roman',
                        fontSize: 12,
                        fontWeight:
                        FontWeight
                            .bold,
                        letterSpacing:
                        1.2,
                        color:
                        Color(
                          0xFF9A8BA6,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        fontFamily:
                        'Times New Roman',
                        fontSize: 19,
                        fontWeight:
                        FontWeight
                            .bold,
                        color:
                        Color(
                          0xFF6B5B7B,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 18,
          ),
          Container(
            width:
            double.infinity,
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.white,
              borderRadius:
              BorderRadius
                  .circular(
                14,
              ),
            ),
            child:
            Row(
              children: [
                Icon(
                  isPaused
                      ? Icons
                      .pause_circle_rounded
                      : isPlaying
                      ? Icons
                      .volume_up_rounded
                      : Icons
                      .headphones_rounded,
                  color:
                  const Color(
                    0xFF8B739F,
                  ),
                  size: 25,
                ),
                const SizedBox(
                  width: 12,
                ),
                if (isPlaying &&
                    !isPaused)
                  buildWaveform()
                else if (isPaused)
                  const Icon(
                    Icons
                        .pause_rounded,
                    color:
                    Color(
                      0xFF8B739F,
                    ),
                  ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child:
                  Text(
                    isPaused
                        ? 'Audiobook paused'
                        : isPlaying
                        ? 'Reading your book...'
                        : 'Ready to listen',
                    style:
                    const TextStyle(
                      fontFamily:
                      'Times New Roman',
                      fontSize: 14,
                      fontWeight:
                      FontWeight
                          .w600,
                      color:
                      Color(
                        0xFF6B5B7B,
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
  }

  // ============================================================
  // AUDIO PROGRESS
  // ============================================================

  Widget buildAudioProgress() {
    final double totalSeconds =
        estimatedTotalSeconds;

    final double currentSeconds =
        estimatedCurrentSeconds;

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        18,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color:
          const Color(
            0xFFE8DDF1,
          ),
        ),
      ),
      child:
      Column(
        children: [
          SliderTheme(
            data:
            SliderTheme.of(
              context,
            ).copyWith(
              trackHeight: 5,
              thumbShape:
              const RoundSliderThumbShape(
                enabledThumbRadius:
                7,
              ),
              overlayShape:
              const RoundSliderOverlayShape(
                overlayRadius:
                16,
              ),
              activeTrackColor:
              const Color(
                0xFFC8B6E2,
              ),
              inactiveTrackColor:
              const Color(
                0xFFE8DDF1,
              ),
              thumbColor:
              const Color(
                0xFF8B739F,
              ),
            ),
            child:
            Slider(
              value: progress,
              min: 0,
              max: 1,
              onChanged:
                  (value) {
                if (speechChunks
                    .isEmpty) {
                  return;
                }

                final int target =
                (value *
                    (speechChunks
                        .length -
                        1))
                    .round();

                _seekToChunk(
                  target,
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
            children: [
              Text(
                formatDuration(
                  currentSeconds,
                ),
                style:
                const TextStyle(
                  fontFamily:
                  'Times New Roman',
                  fontSize: 13,
                  color:
                  Color(
                    0xFF7D7087,
                  ),
                ),
              ),
              Text(
                formatDuration(
                  totalSeconds,
                ),
                style:
                const TextStyle(
                  fontFamily:
                  'Times New Roman',
                  fontSize: 13,
                  color:
                  Color(
                    0xFF7D7087,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Row(
            mainAxisAlignment:
            MainAxisAlignment
                .center,
            children: [
              IconButton(
                tooltip:
                'Back 10 seconds',
                onPressed:
                speechChunks
                    .isEmpty
                    ? null
                    : seekBackward10Seconds,
                iconSize: 34,
                color:
                const Color(
                  0xFF8B739F,
                ),
                icon:
                const Icon(
                  Icons
                      .replay_10_rounded,
                ),
              ),
              const SizedBox(
                width: 25,
              ),
              Container(
                width: 58,
                height: 58,
                decoration:
                const BoxDecoration(
                  color:
                  Color(
                    0xFFC8B6E2,
                  ),
                  shape:
                  BoxShape.circle,
                ),
                child:
                IconButton(
                  onPressed:
                  togglePlayPause,
                  iconSize: 32,
                  color:
                  Colors.white,
                  icon: Icon(
                    isPlaying &&
                        !isPaused
                        ? Icons
                        .pause_rounded
                        : Icons
                        .play_arrow_rounded,
                  ),
                ),
              ),
              const SizedBox(
                width: 25,
              ),
              IconButton(
                tooltip:
                'Forward 10 seconds',
                onPressed:
                speechChunks
                    .isEmpty
                    ? null
                    : seekForward10Seconds,
                iconSize: 34,
                color:
                const Color(
                  0xFF8B739F,
                ),
                icon:
                const Icon(
                  Icons
                      .forward_10_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          const Text(
            '10 seconds',
            style:
            TextStyle(
              fontFamily:
              'Times New Roman',
              fontSize: 12,
              color:
              Color(
                0xFF9A8BA6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(
        0xFFFFF9FC,
      ),
      appBar:
      AppBar(
        backgroundColor:
        const Color(
          0xFFFFF9FC,
        ),
        elevation: 0,
        iconTheme:
        const IconThemeData(
          color:
          Color(
            0xFF6B5B7B,
          ),
        ),
        title:
        const Text(
          'Audiobook',
          style:
          TextStyle(
            fontFamily:
            'Times New Roman',
            color:
            Color(
              0xFF6B5B7B,
            ),
            fontWeight:
            FontWeight
                .bold,
          ),
        ),
      ),
      body:
      isLoading
          ? const Center(
        child:
        CircularProgressIndicator(
          color:
          Color(
            0xFFC8B6E2,
          ),
        ),
      )
          : extractedText
          .isEmpty
          ? const Center(
        child:
        Text(
          'No readable text found.',
          style:
          TextStyle(
            fontFamily:
            'Times New Roman',
            fontSize:
            18,
          ),
        ),
      )
          : SafeArea(
        child:
        SingleChildScrollView(
          padding:
          const EdgeInsets
              .fromLTRB(
            20,
            10,
            20,
            30,
          ),
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Text(
                widget.title,
                style:
                const TextStyle(
                  fontFamily:
                  'Times New Roman',
                  fontSize:
                  27,
                  fontWeight:
                  FontWeight
                      .bold,
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
                'Listen to your complete book 🎧',
                style:
                TextStyle(
                  fontFamily:
                  'Times New Roman',
                  fontSize:
                  16,
                  color:
                  Color(
                    0xFF7D7087,
                  ),
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              Center(
                child:
                Container(
                  width:
                  105,
                  height:
                  105,
                  decoration:
                  const BoxDecoration(
                    color:
                    Color(
                      0xFFE8DDF1,
                    ),
                    shape:
                    BoxShape
                        .circle,
                  ),
                  child:
                  const Icon(
                    Icons
                        .headphones_rounded,
                    size:
                    55,
                    color:
                    Color(
                      0xFF8B739F,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              buildCurrentAudioCard(),
              const SizedBox(
                height: 20,
              ),
              buildAudioProgress(),
              const SizedBox(
                height: 22,
              ),
              Center(
                child:
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,
                  children: [
                    if (isPlaying)
                      OutlinedButton
                          .icon(
                        onPressed:
                        stopAudiobook,
                        icon:
                        const Icon(
                          Icons
                              .stop_rounded,
                        ),
                        label:
                        const Text(
                          'Stop',
                          style:
                          TextStyle(
                            fontFamily:
                            'Times New Roman',
                          ),
                        ),
                        style:
                        OutlinedButton
                            .styleFrom(
                          foregroundColor:
                          const Color(
                            0xFF8B739F,
                          ),
                          side:
                          const BorderSide(
                            color:
                            Color(
                              0xFFC8B6E2,
                            ),
                          ),
                        ),
                      ),
                    if (isPlaying)
                      const SizedBox(
                        width:
                        12,
                      ),
                    ElevatedButton
                        .icon(
                      onPressed:
                      togglePlayPause,
                      icon:
                      Icon(
                        isPlaying &&
                            !isPaused
                            ? Icons
                            .pause_rounded
                            : Icons
                            .play_arrow_rounded,
                      ),
                      label:
                      Text(
                        isPlaying
                            ? isPaused
                            ? 'Resume'
                            : 'Pause'
                            : 'Play Full Book',
                        style:
                        const TextStyle(
                          fontFamily:
                          'Times New Roman',
                          fontSize:
                          15,
                          fontWeight:
                          FontWeight
                              .w600,
                        ),
                      ),
                      style:
                      ElevatedButton
                          .styleFrom(
                        backgroundColor:
                        const Color(
                          0xFFC8B6E2,
                        ),
                        foregroundColor:
                        Colors.white,
                        elevation:
                        0,
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal:
                          18,
                          vertical:
                          13,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 25,
              ),

              // ==================================================
              // AUDIO SETTINGS
              // ==================================================

              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets
                    .all(
                  18,
                ),
                decoration:
                BoxDecoration(
                  color:
                  Colors.white,
                  borderRadius:
                  BorderRadius
                      .circular(
                    18,
                  ),
                  border:
                  Border.all(
                    color:
                    const Color(
                      0xFFE8DDF1,
                    ),
                  ),
                ),
                child:
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons
                              .speed_rounded,
                          color:
                          Color(
                            0xFF8B739F,
                          ),
                        ),
                        const SizedBox(
                          width:
                          10,
                        ),
                        const Text(
                          'Voice Speed',
                          style:
                          TextStyle(
                            fontFamily:
                            'Times New Roman',
                            fontSize:
                            16,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                        const Spacer(),
                        DropdownButton<double>(
                          value:
                          voiceSpeed,
                          underline:
                          const SizedBox(),
                          items:
                          const [
                            DropdownMenuItem(
                              value:
                              0.75,
                              child:
                              Text(
                                '0.75x',
                                style:
                                TextStyle(
                                  fontFamily:
                                  'Times New Roman',
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value:
                              1.0,
                              child:
                              Text(
                                '1.0x',
                                style:
                                TextStyle(
                                  fontFamily:
                                  'Times New Roman',
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value:
                              1.25,
                              child:
                              Text(
                                '1.25x',
                                style:
                                TextStyle(
                                  fontFamily:
                                  'Times New Roman',
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value:
                              1.5,
                              child:
                              Text(
                                '1.5x',
                                style:
                                TextStyle(
                                  fontFamily:
                                  'Times New Roman',
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value:
                              2.0,
                              child:
                              Text(
                                '2.0x',
                                style:
                                TextStyle(
                                  fontFamily:
                                  'Times New Roman',
                                ),
                              ),
                            ),
                          ],
                          onChanged:
                              (value) {
                            if (value !=
                                null) {
                              changeSpeed(
                                value,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(
                      height:
                      15,
                    ),

                    // VOLUME
                    Row(
                      children: [
                        Icon(
                          volume ==
                              0
                              ? Icons
                              .volume_off_rounded
                              : Icons
                              .volume_up_rounded,
                          color:
                          const Color(
                            0xFF8B739F,
                          ),
                        ),
                        const SizedBox(
                          width:
                          10,
                        ),
                        const Text(
                          'Volume',
                          style:
                          TextStyle(
                            fontFamily:
                            'Times New Roman',
                            fontSize:
                            16,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                        Expanded(
                          child:
                          Slider(
                            value:
                            volume,
                            min:
                            0,
                            max:
                            1,
                            divisions:
                            10,
                            activeColor:
                            const Color(
                              0xFFC8B6E2,
                            ),
                            inactiveColor:
                            const Color(
                              0xFFE8DDF1,
                            ),
                            onChanged:
                            changeVolume,
                          ),
                        ),
                        Text(
                          '${(volume * 100).round()}%',
                          style:
                          const TextStyle(
                            fontFamily:
                            'Times New Roman',
                            fontSize:
                            14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height:
                      10,
                    ),

                    // EXPRESSIVE READING
                    Row(
                      children: [
                        const Icon(
                          Icons
                              .auto_awesome_rounded,
                          color:
                          Color(
                            0xFF8B739F,
                          ),
                        ),
                        const SizedBox(
                          width:
                          10,
                        ),
                        const Expanded(
                          child:
                          Text(
                            'Expressive Reading',
                            style:
                            TextStyle(
                              fontFamily:
                              'Times New Roman',
                              fontSize:
                              16,
                              fontWeight:
                              FontWeight
                                  .w600,
                            ),
                          ),
                        ),
                        Switch(
                          value:
                          expressiveReading,
                          activeColor:
                          const Color(
                            0xFFC8B6E2,
                          ),
                          onChanged:
                              (value) {
                            setState(
                                  () {
                                expressiveReading =
                                    value;
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(
                      height:
                      4,
                    ),
                    const Align(
                      alignment:
                      Alignment
                          .centerLeft,
                      child:
                      Text(
                        'Adds gentle pauses and natural changes in tone.',
                        style:
                        TextStyle(
                          fontFamily:
                          'Times New Roman',
                          fontSize:
                          13,
                          color:
                          Color(
                            0xFF8D8196,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // ==================================================
              // AUDIOBOOK INFORMATION
              // ==================================================

              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets
                    .all(
                  16,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFFFF3F8,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    16,
                  ),
                  border:
                  Border.all(
                    color:
                    const Color(
                      0xFFF0DDE8,
                    ),
                  ),
                ),
                child:
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    const Icon(
                      Icons
                          .info_outline_rounded,
                      color:
                      Color(
                        0xFF8B739F,
                      ),
                    ),
                    const SizedBox(
                      width:
                      10,
                    ),
                    const Expanded(
                      child:
                      Text(
                        'ReadAura plays the complete book as one continuous audiobook. You can pause, resume, move 10 seconds backward or forward, adjust the voice speed, and control the volume while listening.',
                        style:
                        TextStyle(
                          fontFamily:
                          'Times New Roman',
                          fontSize:
                          14,
                          height:
                          1.4,
                          color:
                          Color(
                            0xFF6B5B7B,
                          ),
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
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    /*
      Best-effort save when the user leaves
      the audiobook screen.

      We intentionally don't await here because
      Flutter dispose() cannot be async.
    */

    _saveAudiobookProgress();

    speechSession++;

    readAuraStop();

    waveController.dispose();

    super.dispose();
  }
}