class ReadingHistoryService {
  static final List<Map<String, String>> history = [];

  static void addToHistory({
    required String title,
    required String author,
    required String personality,
    required String progress,
  }) {
    // Remove the book if it already exists
    history.removeWhere(
          (book) => book['title'] == title,
    );

    // Add it to the beginning as the most recently opened book
    history.insert(0, {
      'title': title,
      'author': author,
      'personality': personality,
      'progress': progress,
    });
  }

  static List<Map<String, String>> getHistory() {
    return List<Map<String, String>>.from(history);
  }

  static void clearHistory() {
    history.clear();
  }
}