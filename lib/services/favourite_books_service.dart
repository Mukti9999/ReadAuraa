import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum FavouriteBookResult {
  added,
  alreadyExists,
  notLoggedIn,
  error,
}

class FavouriteBooksService {
  static final List<Map<String, String>> favouriteBooks = [];

  static String _normalize(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  // Load favourite books from Firebase
  static Future<void> loadFavouriteBooks() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        favouriteBooks.clear();
        return;
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance
          .collection('favourite_books')
          .where('userId', isEqualTo: user.uid)
          .get();

      favouriteBooks.clear();

      for (final document in snapshot.docs) {
        final data = document.data();

        favouriteBooks.add({
          'id': document.id,
          'title': data['title']?.toString() ?? '',
          'author': data['author']?.toString() ?? '',
          'genre': data['genre']?.toString() ?? '',
          'personality': data['personality']?.toString() ?? '',
          'description': data['description']?.toString() ?? '',
          'coverImage': data['coverImage']?.toString() ?? '',
          'fileURL': data['fileURL']?.toString() ?? '',
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading favourite books: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // Add book to favourites
  static Future<FavouriteBookResult> addFavouriteBook({
    required String title,
    required String author,
    required String genre,
    required String personality,
    required String description,
    required String coverImage,
    required String fileURL,
  }) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return FavouriteBookResult.notLoggedIn;
      }

      /*
       * We only query by userId here.
       *
       * The old code used:
       * userId + title
       *
       * and Firebase could require a composite index.
       *
       * We now check the title locally after getting this user's
       * favourite books.
       */
      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance
          .collection('favourite_books')
          .where('userId', isEqualTo: user.uid)
          .get();

      final String normalizedTitle = _normalize(title);

      final bool alreadyExists = snapshot.docs.any((document) {
        final data = document.data();

        final String existingTitle =
            data['title']?.toString() ?? '';

        return _normalize(existingTitle) == normalizedTitle;
      });

      if (alreadyExists) {
        return FavouriteBookResult.alreadyExists;
      }

      final DocumentReference<Map<String, dynamic>> document =
      await FirebaseFirestore.instance
          .collection('favourite_books')
          .add({
        'userId': user.uid,
        'title': title,
        'author': author,
        'genre': genre,
        'personality': personality,
        'description': description,
        'coverImage': coverImage,
        'fileURL': fileURL,
        'createdAt': FieldValue.serverTimestamp(),
      });

      favouriteBooks.add({
        'id': document.id,
        'title': title,
        'author': author,
        'genre': genre,
        'personality': personality,
        'description': description,
        'coverImage': coverImage,
        'fileURL': fileURL,
      });

      return FavouriteBookResult.added;
    } catch (e, stackTrace) {
      debugPrint('ERROR ADDING FAVOURITE BOOK: $e');
      debugPrintStack(stackTrace: stackTrace);

      return FavouriteBookResult.error;
    }
  }

  // Remove favourite book
  static Future<void> removeFavouriteBook(int index) async {
    try {
      if (index < 0 || index >= favouriteBooks.length) {
        return;
      }

      final Map<String, String> favouriteBook =
      favouriteBooks[index];

      final String? documentId = favouriteBook['id'];

      if (documentId != null && documentId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('favourite_books')
            .doc(documentId)
            .delete();
      }

      favouriteBooks.removeAt(index);
    } catch (e, stackTrace) {
      debugPrint('Error removing favourite book: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}