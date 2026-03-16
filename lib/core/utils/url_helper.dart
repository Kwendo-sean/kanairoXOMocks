import 'package:kanairoxo/utils/constants.dart';

class UrlHelper {
  static String fixMediaUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    
    // Already a full URL
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    
    // Relative path — prepend base URL
    final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '');
    final path = raw.startsWith('/') ? raw : '/$raw';
    
    return '$base$path';
  }
  
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    // Check if it's a valid data URI (like base64) or a network URL
    if (url.startsWith('data:image')) return true;
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.hasAuthority;
  }
}
