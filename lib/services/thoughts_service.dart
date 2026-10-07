import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThoughtsService {
  // Local cache
  static final Map<String, String> thoughts = {};

  // --------------------------------------------------
  // SAVE THOUGHT TO FIREBASE
  // --------------------------------------------------

  static Future<bool> saveThought({
    required String bookTitle,
    required String thought,
  }) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return false;
      }

      final String documentId =
          '${user.uid}_${Uri.encodeComponent(bookTitle)}';

      await FirebaseFirestore.instance
          .collection('journals')
          .doc(documentId)
          .set(
        {
          'userId': user.uid,
          'bookTitle': bookTitle,
          'thoughts': thought,
          'date': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Keep local copy as well
      thoughts[bookTitle] = thought;

      return true;
    } catch (e) {
      print('Thought save error: $e');
      return false;
    }
  }

  // --------------------------------------------------
  // GET THOUGHT FOR ONE BOOK
  // --------------------------------------------------

  static Future<String> getThought(String bookTitle) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return thoughts[bookTitle] ?? '';
      }

      final String documentId =
          '${user.uid}_${Uri.encodeComponent(bookTitle)}';

      final DocumentSnapshot<Map<String, dynamic>> document =
      await FirebaseFirestore.instance
          .collection('journals')
          .doc(documentId)
          .get();

      if (document.exists && document.data() != null) {
        final Map<String, dynamic> data = document.data()!;

        final String thought =
            data['thoughts']?.toString() ?? '';

        thoughts[bookTitle] = thought;

        return thought;
      }

      return '';
    } catch (e) {
      print('Thought load error: $e');
      return thoughts[bookTitle] ?? '';
    }
  }

  // --------------------------------------------------
  // GET ALL THOUGHTS FOR CURRENT USER
  // --------------------------------------------------

  static Stream<QuerySnapshot<Map<String, dynamic>>>
  getThoughtsStream() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('journals')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  // --------------------------------------------------
  // GET THOUGHT COUNT
  // --------------------------------------------------

  static Stream<int> getThoughtCountStream() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(0);
    }

    return FirebaseFirestore.instance
        .collection('journals')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}