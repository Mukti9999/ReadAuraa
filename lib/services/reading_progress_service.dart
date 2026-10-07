class ReadingProgressService {
  static final Map<String, int> currentPages = {};

  static void saveProgress({
    required String bookTitle,
    required int currentPage,
  }) {
    currentPages[bookTitle] = currentPage;
  }

  static int getProgress(String bookTitle) {
    return currentPages[bookTitle] ?? 1;
  }
}