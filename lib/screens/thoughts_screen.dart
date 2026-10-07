import 'package:flutter/material.dart';

import '../services/thoughts_service.dart';

class ThoughtsScreen extends StatefulWidget {
  final String bookTitle;

  const ThoughtsScreen({
    super.key,
    required this.bookTitle,
  });

  @override
  State<ThoughtsScreen> createState() => _ThoughtsScreenState();
}

class _ThoughtsScreenState extends State<ThoughtsScreen> {
  final TextEditingController _thoughtsController =
  TextEditingController();

  bool saved = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadThought();
  }

  // --------------------------------------------------
  // LOAD SAVED THOUGHT
  // --------------------------------------------------

  Future<void> _loadThought() async {
    final String savedThought =
    await ThoughtsService.getThought(widget.bookTitle);

    if (!mounted) return;

    if (savedThought.isNotEmpty) {
      setState(() {
        _thoughtsController.text = savedThought;
        saved = true;
      });
    }
  }

  @override
  void dispose() {
    _thoughtsController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // SAVE THOUGHT
  // --------------------------------------------------

  Future<void> _saveThoughts() async {
    final String thought =
    _thoughtsController.text.trim();

    if (thought.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Write something before saving 🌷',
            style: TextStyle(
              fontFamily: 'Times New Roman',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    final bool success =
    await ThoughtsService.saveThought(
      bookTitle: widget.bookTitle,
      thought: thought,
    );

    if (!mounted) return;

    setState(() {
      isSaving = false;
      saved = success;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your thoughts have been saved 💗',
            style: TextStyle(
              fontFamily: 'Times New Roman',
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save your thoughts. Please login and try again.',
            style: TextStyle(
              fontFamily: 'Times New Roman',
            ),
          ),
        ),
      );
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
          'My Thoughts',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            color: Color(0xFF6B5B7B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

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
            const Text(
              'What are you thinking? 💭',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 25,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Write down anything that comes to your mind while reading.',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 14,
                color: Color(0xFF9A8FA3),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8DDF1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8B6E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Currently Reading',
                          style: TextStyle(
                            fontFamily: 'Times New Roman',
                            fontSize: 12,
                            color: Color(0xFF8B739F),
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          widget.bookTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Times New Roman',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B5B7B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                controller: _thoughtsController,
                maxLines: 12,
                onChanged: (value) {
                  if (saved) {
                    setState(() {
                      saved = false;
                    });
                  }
                },
                decoration: const InputDecoration(
                  hintText:
                  'Write your thoughts here...\n\n'
                      '• What did you feel while reading?\n'
                      '• Did any character remind you of someone?\n'
                      '• What line or moment stayed with you?\n'
                      '• What did you learn from this chapter?',
                  hintStyle: TextStyle(
                    fontFamily: 'Times New Roman',
                    color: Color(0xFFB5AAB9),
                    height: 1.6,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(20),
                ),
                style: const TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF5E5368),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (saved)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDEBDD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF6F9073),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Thought saved successfully 💗',
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          color: Color(0xFF607B64),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                isSaving ? null : _saveThoughts,
                icon: isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.save_rounded,
                ),
                label: Text(
                  isSaving
                      ? 'Saving...'
                      : 'Save My Thoughts',
                  style: const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFFC8B6E2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(17),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Center(
              child: Text(
                'Your thoughts are part of your reading journey ✨',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 12,
                  color: Color(0xFFAAA0AE),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}