/// Utility functions for avatar URL handling and manipulation
class AvatarUtils {
  /// Normalizes an avatar URL by fixing legacy cache-buster format issues
  /// and ensuring query parameters are properly formatted.
  ///
  /// This handles cases like:
  /// - Legacy format: `...?token=xyz?v=123` (double question marks)
  /// - Missing parameters that should be parsed
  ///
  /// Example:
  /// ```dart
  /// final url = 'https://example.com/avatar.jpg?token=abc?v=123';
  /// final normalized = AvatarUtils.normalizeUrl(url);
  /// // Returns: 'https://example.com/avatar.jpg?token=abc&v=123'
  /// ```
  static String normalizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final params = Map<String, String>.from(uri.queryParameters);

      // Fix legacy cache-buster format: ...?token=xyz?v=123
      final token = params['token'];
      if (token != null && token.contains('?v=')) {
        final parts = token.split('?v=');
        params['token'] = parts.first;
        if (parts.length > 1 && !params.containsKey('v')) {
          params['v'] = parts.last;
        }
      }

      // Extract trailing ?v= if it wasn't parsed as a query param
      if (!params.containsKey('v') && url.contains('?v=')) {
        final suffix = url.split('?v=').last;
        if (suffix.isNotEmpty && !suffix.contains('&')) {
          params['v'] = suffix;
        }
      }

      if (params.isEmpty) {
        return url;
      }

      return uri.replace(queryParameters: params).toString();
    } catch (_) {
      return url;
    }
  }
}
