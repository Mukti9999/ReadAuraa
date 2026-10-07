import 'package:pdfrx/pdfrx.dart';

class PdfTextService {
  /// Extracts readable text from every page of a PDF asset.
  static Future<String> extractTextFromAsset(
      String assetPath,
      ) async {
    PdfDocument? document;

    try {
      document = await PdfDocument.openAsset(assetPath);

      final StringBuffer fullText = StringBuffer();

      for (final page in document.pages) {
        try {
          final pageText = await page.loadText();

          if (pageText != null &&
              pageText.fullText.trim().isNotEmpty) {
            fullText.writeln(pageText.fullText);
            fullText.writeln();
          }
        } catch (e) {
          print(
            'Could not extract text from page '
                '${page.pageNumber}: $e',
          );
        }
      }

      return fullText.toString().trim();
    } catch (e) {
      print('PDF text extraction error: $e');

      return '';
    } finally {
      if (document != null) {
        await document.dispose();
      }
    }
  }
}