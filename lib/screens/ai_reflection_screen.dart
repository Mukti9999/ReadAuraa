import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIReflectionScreen extends StatefulWidget {
  final String bookTitle;

  const AIReflectionScreen({
    super.key,
    this.bookTitle = 'The Alchemist',
  });

  @override
  State<AIReflectionScreen> createState() =>
      _AIReflectionScreenState();
}

class _AIReflectionScreenState extends State<AIReflectionScreen> {
  final TextEditingController _reflectionController =
  TextEditingController();

  bool reflectionGenerated = false;
  bool isLoadingReflection = true;
  bool isSavingReflection = false;

  String reflectionText =
      'Your thoughts show that this story connected with you on a personal level. '
      'The ideas you noticed may help you understand your own feelings, choices '
      'and perspective a little better. Keep exploring what the story means to you. 🌸';

  // FIRESTORE DOCUMENT ID
  String get _documentId {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return '';
    }

    final String safeBookTitle =
    Uri.encodeComponent(widget.bookTitle);

    return '${user.uid}_$safeBookTitle';
  }

  @override
  void initState() {
    super.initState();
    _loadPreviousReflection();
  }

  // LOAD PREVIOUS REFLECTION
  Future<void> _loadPreviousReflection() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          isLoadingReflection = false;
        });

        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> doc =
      await FirebaseFirestore.instance
          .collection('ai_reflection')
          .doc(_documentId)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data();

        final String savedThoughts =
            data?['thoughts']?.toString() ?? '';

        final String savedReflection =
            data?['reflection']?.toString() ?? '';

        setState(() {
          if (savedThoughts.isNotEmpty) {
            _reflectionController.text =
                savedThoughts;
          }

          if (savedReflection.isNotEmpty) {
            reflectionText = savedReflection;
            reflectionGenerated = true;
          }

          isLoadingReflection = false;
        });
      } else {
        setState(() {
          isLoadingReflection = false;
        });
      }
    } catch (e) {
      debugPrint(
        'Error loading AI reflection: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoadingReflection = false;
      });
    }
  }

  // GENERATE REFLECTION
  Future<void> generateReflection() async {
    final String thoughts =
    _reflectionController.text.trim();

    if (thoughts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Write a few thoughts first 💭',
          ),
        ),
      );
      return;
    }

    setState(() {
      reflectionGenerated = true;
      isSavingReflection = true;
    });

    // Current temporary reflection text.
    // A real AI API will replace this later.
    final String generatedText =
        'Your thoughts show that this story connected with you on a personal level. '
        'The ideas you noticed may help you understand your own feelings, choices '
        'and perspective a little better. Keep exploring what the story means to you. 🌸';

    setState(() {
      reflectionText = generatedText;
    });

    await _saveReflectionToFirebase(
      thoughts: thoughts,
      reflection: generatedText,
    );

    if (!mounted) return;

    setState(() {
      isSavingReflection = false;
    });
  }

  // SAVE REFLECTION TO FIREBASE
  Future<void> _saveReflectionToFirebase({
    required String thoughts,
    required String reflection,
  }) async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      await FirebaseFirestore.instance
          .collection('ai_reflection')
          .doc(_documentId)
          .set(
        {
          'userId': user.uid,
          'bookId': widget.bookTitle,
          'bookTitle': widget.bookTitle,
          'thoughts': thoughts,
          'reflection': reflection,
          'date': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reflection saved successfully ✨',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Error saving AI reflection: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save reflection. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingReflection) {
      return Scaffold(
        backgroundColor:
        const Color(0xFFFFF9FC),
        appBar: AppBar(
          backgroundColor:
          const Color(0xFFFFF9FC),
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
            'AI Reflection ✨',
            style: TextStyle(
              color: Color(0xFF6B5B7B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFC8B6E2),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(0xFFFFF9FC),
      appBar: AppBar(
        backgroundColor:
        const Color(0xFFFFF9FC),
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
          'AI Reflection ✨',
          style: TextStyle(
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
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'Reflect on your reading 💭',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Share what you felt or learned, and ReadAura will help you reflect on it.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF9A8FA3),
              ),
            ),

            const SizedBox(height: 22),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFE8DDF1),
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration:
                    const BoxDecoration(
                      color: Color(0xFFC8B6E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Currently reflecting on',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8B739F),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          widget.bookTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Color(0xFF6B5B7B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'What did you think about it?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _reflectionController,
              maxLines: 7,
              decoration: InputDecoration(
                hintText:
                'Write about a feeling, idea, lesson or moment that stayed with you...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFAAA0B2),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.all(17),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isSavingReflection
                    ? null
                    : generateReflection,
                icon: isSavingReflection
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.auto_awesome_rounded,
                ),
                label: Text(
                  isSavingReflection
                      ? 'Saving Reflection...'
                      : 'Generate Reflection',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFFC8B6E2),
                  foregroundColor:
                  Colors.white,
                  disabledBackgroundColor:
                  const Color(0xFFC8B6E2),
                  disabledForegroundColor:
                  Colors.white,
                  elevation: 0,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            if (reflectionGenerated) ...[
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFFFE7B8),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons
                              .auto_awesome_rounded,
                          color:
                          Color(0xFF8B739F),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Your Reflection ✨',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Color(0xFF6B5B7B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Text(
                      reflectionText,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color:
                        Color(0xFF7D7183),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 25),

            const Center(
              child: Text(
                'Read. Feel. Reflect. 💗',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle:
                  FontStyle.italic,
                  color:
                  Color(0xFF9A8FA3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}