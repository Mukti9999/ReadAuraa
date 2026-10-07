import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum FavouritePassageResult {
  added,
  alreadyExists,
  notLoggedIn,
  error,
}

class FavouriteService {
  static final List<Map<String, String>> favourites = [];

  static String _normalize(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  // Load favourite passages from Firebase
  static Future<void> loadFavourites() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        favourites.clear();
        return;
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance
          .collection('favourite_passages')
          .where('userId', isEqualTo: user.uid)
          .get();

      favourites.clear();

      for (final document in snapshot.docs) {
        final data = document.data();

        favourites.add({
          'id': document.id,
          'title': data['title']?.toString() ?? '',
          'author': data['author']?.toString() ?? '',
          'type': data['type']?.toString() ?? 'Quote',
          'content': data['content']?.toString() ?? '',
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading favourite passages: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // Add favourite passage
  static Future<FavouritePassageResult> addFavourite({
    required String title,
    required String author,
    required String type,
    required String content,
  }) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return FavouritePassageResult.notLoggedIn;
      }

      /*
       * Only query using userId.
       *
       * The old code used three where conditions:
       * userId + title + content
       *
       * That can require a Firestore composite index.
       *
       * We now fetch this user's passages and compare title/content
       * locally.
       */
      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance
          .collection('favourite_passages')
          .where('userId', isEqualTo: user.uid)
          .get();

      final String normalizedTitle = _normalize(title);
      final String normalizedContent = _normalize(content);

      final bool alreadyExists = snapshot.docs.any((document) {
        final data = document.data();

        final String existingTitle =
            data['title']?.toString() ?? '';

        final String existingContent =
            data['content']?.toString() ?? '';

        return _normalize(existingTitle) == normalizedTitle &&
            _normalize(existingContent) == normalizedContent;
      });

      if (alreadyExists) {
        return FavouritePassageResult.alreadyExists;
      }

      final DocumentReference<Map<String, dynamic>> document =
      await FirebaseFirestore.instance
          .collection('favourite_passages')
          .add({
        'userId': user.uid,
        'title': title,
        'author': author,
        'type': type,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });

      favourites.add({
        'id': document.id,
        'title': title,
        'author': author,
        'type': type,
        'content': content,
      });

      return FavouritePassageResult.added;
    } catch (e, stackTrace) {
      debugPrint('ERROR ADDING FAVOURITE PASSAGE: $e');
      debugPrintStack(stackTrace: stackTrace);

      return FavouritePassageResult.error;
    }
  }

  // Remove favourite passage
  static Future<void> removeFavourite(int index) async {
    try {
      if (index < 0 || index >= favourites.length) {
        return;
      }

      final Map<String, String> favourite =
      favourites[index];

      final String? documentId = favourite['id'];

      if (documentId != null && documentId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('favourite_passages')
            .doc(documentId)
            .delete();
      }

      favourites.removeAt(index);
    } catch (e, stackTrace) {
      debugPrint('Error removing favourite passage: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}