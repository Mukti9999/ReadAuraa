import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'thoughts_screen.dart';
import 'favourites_screen.dart';
import 'music_screen.dart';
import 'ai_reflection_screen.dart';
import '../services/favourite_service.dart';
import '../services/reading_progress_service.dart';
import '../services/reading_history_service.dart';

class ReadingScreen extends StatefulWidget {
  final String title;
  final String author;
  final String personality;

  const ReadingScreen({
    super.key,
    required this.title,
    required this.author,
    required this.personality,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  int currentPage = 1;
  final int totalPages = 3;

  final AudioPlayer player = AudioPlayer();

  bool isMusicPlaying = false;
  bool readingMode = false;

  double volume = 0.5;

  final List<String> passages = [
    'It was a beautiful day, and the world seemed a little quieter than usual.',
    'Reading is more than simply following words on a page.',
    'Sometimes, a story helps us discover a small part of ourselves.',
  ];

  @override
  void initState() {
    super.initState();

    currentPage =
        ReadingProgressService.getProgress(widget.title);

    ReadingHistoryService.addToHistory(
      title: widget.title,
      author: widget.author,
      personality: widget.personality,
      progress: 'Page $currentPage of $totalPages',
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Color getBackgroundColor() {
    if (readingMode) {
      return const Color(0xFF1E1B22);
    }

    switch (widget.personality) {
      case 'Romance':
        return const Color(0xFFFFF0F5);

      case 'Thriller':
        return const Color(0xFFE8E8EC);

      case 'Inspiring':
        return const Color(0xFFFFF1DF);

      default:
        return const Color(0xFFFFF9FC);
    }
  }

  Future<void> toggleMusic() async {
    if (isMusicPlaying) {
      await player.pause();

      setState(() {
        isMusicPlaying = false;
      });
    } else {
      await player.setVolume(volume);

      await player.play(
          AssetSource('reading_music/reading_music.mp3')
      );

      setState(() {
        isMusicPlaying = true;
      });
    }
  }

  Future<void> openMusicScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MusicScreen(),
      ),
    );
  }

  void savePassage(String passage) {
    FavouriteService.addFavourite(
      title: widget.title,
      author: widget.author,
      type: 'Favourite Line',
      content: passage,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❤️ Added to Favourites!'),
      ),
    );
  }

  void nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });

      ReadingProgressService.saveProgress(
        bookTitle: widget.title,
        currentPage: currentPage,
      );

      ReadingHistoryService.addToHistory(
        title: widget.title,
        author: widget.author,
        personality: widget.personality,
        progress: 'Page $currentPage of $totalPages',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 You have reached the end of the book!'),
        ),
      );
    }
  }
  void previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });

      ReadingProgressService.saveProgress(
        bookTitle: widget.title,
        currentPage: currentPage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = currentPage / totalPages;

    return Scaffold(
      backgroundColor: getBackgroundColor(),

      appBar: AppBar(
        backgroundColor: getBackgroundColor(),
        elevation: 0,

        title: const Text(
          'Reading 📖',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B5B7B),
          ),
        ),

        actions: [
          IconButton(
            icon: Icon(
              isMusicPlaying
                  ? Icons.music_note_rounded
                  : Icons.music_off_rounded,
              color: const Color(0xFF6B5B7B),
            ),
            onPressed: toggleMusic,
          ),

          IconButton(
            icon: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFF6B5B7B),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const FavouritesScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(22),

        child: Column(
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              widget.author,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF9A8FA3),
              ),
            ),

            const SizedBox(height: 12),

            // READING MODE TOGGLE
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: readingMode
                    ? const Color(0xFF2A2630)
                    : Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Icon(
                    readingMode
                        ? Icons.menu_book_rounded
                        : Icons.menu_book_outlined,
                    color: const Color(0xFF6B5B7B),
                  ),

                  const SizedBox(width: 10),

                  const Expanded(
                    child: Text(
                      'Night Reading🌙',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B5B7B),
                      ),
                    ),
                  ),

                  Switch(
                    value: readingMode,
                    activeColor: const Color(0xFFC8B6E2),
                    onChanged: (value) {
                      setState(() {
                        readingMode = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            if (!readingMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8DDF1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.personality == 'Romance'
                            ? Icons.favorite_rounded
                            : widget.personality == 'Thriller'
                            ? Icons.bolt_rounded
                            : Icons.auto_awesome_rounded,
                        color: const Color(0xFF6B5B7B),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✨ Book Personality',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9A8FA3),
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            widget.personality,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B5B7B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (!readingMode)
              const SizedBox(height: 20),

            LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: Colors.white,
              valueColor:
              const AlwaysStoppedAnimation<Color>(
                Color(0xFFC8B6E2),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Page $currentPage of $totalPages',
              style: const TextStyle(
                color: Color(0xFF9A8FA3),
              ),
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chapter 1',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B5B7B),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: readingMode
                      ? const Color(0xFF2A2630)
                      : Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    passages[currentPage - 1],
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.7,
                      color: readingMode
                          ? const Color(0xFFF3EEF7)
                          : const Color(0xFF5E5368),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Save this line',
                  style: TextStyle(
                    color: Color(0xFF9A8FA3),
                  ),
                ),

                IconButton(
                  icon: const Icon(
                    Icons.favorite_border_rounded,
                    color: Color(0xFF6B5B7B),
                  ),
                  onPressed: () {
                    savePassage(
                      passages[currentPage - 1],
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 5),

            // PAGE CONTROLS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: previousPage,
                    child: const Text('← Previous'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFFC8B6E2),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Next →'),
                  ),
                ),
              ],
            ),

            // EXTRA CONTROLS HIDDEN IN READING MODE
            if (!readingMode) ...[
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ThoughtsScreen(
                                  bookTitle: widget.title,
                                ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.edit_note_rounded,
                      ),
                      label: const Text('My Thoughts'),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AIReflectionScreen(
                                  bookTitle: widget.title,
                                ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.auto_awesome_rounded,
                      ),
                      label: const Text('AI Reflection'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: openMusicScreen,
                  icon: const Icon(
                    Icons.library_music_rounded,
                  ),
                  label: const Text('Music'),
                ),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}