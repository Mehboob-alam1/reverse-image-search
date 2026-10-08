/// Apify Actors for Google Lens–style reverse image search.
///
/// Primary: [googleLensActorId] — supports URL, base64, and file upload.
/// Alternatives (swap in code if needed):
/// - `zen-studio/google-lens-visual-search` — OCR + related links (~$7.99/1k images)
/// - Apify Store "Google Lens API" — multi-mode (visual-match, exact-match, products)
///
/// Get token: https://console.apify.com/account/integrations
class ApifyConfig {
  ApifyConfig._();

  /// johnvc/google-lens-api — visual / exact / product modes, base64-friendly.
  static const String googleLensActorId = 'johnvc~google-lens-api';

  static const Duration actorTimeout = Duration(minutes: 3);

  /// Base64 input stays under Apify payload limits (~6 MB); larger files use a public URL.
  static const int maxBase64Bytes = 4 * 1024 * 1024;

  static const int defaultMaxResults = 50;
}
