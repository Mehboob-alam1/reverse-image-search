import '../core/utils/url_validator.dart';

/// Free Google Lens in the browser (no SerpApi / Apify billing).
class GoogleLensExternal {
  GoogleLensExternal._();

  static String? uploadByUrl(String imageUrl) {
    final url = imageUrl.trim();
    if (!UrlValidator.isValidHttpUrl(url)) return null;
    return 'https://lens.google.com/uploadbyurl?url=${Uri.encodeComponent(url)}';
  }
}
