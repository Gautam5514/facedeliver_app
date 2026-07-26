/// Extracts an event code from whatever a QR code happens to contain.
///
/// Organisers generate QR codes from the web app, which encodes a full
/// registration URL (`https://…/register?eventId=CODE`). But codes also get
/// shared as plain text, so a bare code must work too.
String? parseEventCode(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) {
    final fromQuery = uri.queryParameters['eventId'] ??
        uri.queryParameters['eventid'] ??
        uri.queryParameters['code'];
    if (fromQuery != null && fromQuery.trim().isNotEmpty) {
      return _normalise(fromQuery);
    }

    // Fall back to the last path segment for links shaped like /event/CODE.
    final segments =
        uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (segments.isNotEmpty && segments.last != 'register') {
      return _normalise(segments.last);
    }
    return null;
  }

  // A bare code — reject anything with whitespace or URL punctuation so a
  // random QR code on a poster does not read as a valid event.
  if (RegExp(r'^[A-Za-z0-9_-]{3,64}$').hasMatch(value)) return _normalise(value);
  return null;
}

String _normalise(String value) => value.trim();

/// Suggests a URL-safe code from an event name, e.g.
/// "Sharma Wedding 2026" → "sharma-wedding-2026".
String suggestEventCode(String name) {
  final slug = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isEmpty) return '';
  return slug.length > 40 ? slug.substring(0, 40).replaceAll(RegExp(r'-+$'), '') : slug;
}
