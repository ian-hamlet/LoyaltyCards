/// TEST-020: RFC 9285 Base45 encoding.
///
/// Chosen specifically because its 45-character alphabet is a subset of
/// QR's "alphanumeric mode" character set (0-9, A-Z, space, $ % * + - . /
/// :) - encoding compressed binary data as Base45 lets a QR code use that
/// more space-efficient mode (~5.5 bits/char) instead of the default byte
/// mode (8 bits/char) that a plain base64 string would force. See
/// AlphanumericQr for the QR-construction side of this and
/// RedemptionQrCodec for where this is actually used.
class Base45 {
  Base45._();

  static const String _alphabet =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ \$%*+-./:';

  /// Encodes [data] two bytes at a time into three Base45 characters
  /// (`c + d*45 + e*45*45 = byte0*256 + byte1`), with a two-character
  /// tail for a trailing single byte.
  static String encode(List<int> data) {
    final out = StringBuffer();
    for (var i = 0; i < data.length; i += 2) {
      if (i + 1 < data.length) {
        final n = data[i] * 256 + data[i + 1];
        out.write(_alphabet[n % 45]);
        out.write(_alphabet[(n ~/ 45) % 45]);
        out.write(_alphabet[n ~/ (45 * 45)]);
      } else {
        final n = data[i];
        out.write(_alphabet[n % 45]);
        out.write(_alphabet[n ~/ 45]);
      }
    }
    return out.toString();
  }

  /// Decodes a Base45 string back to bytes. Throws [FormatException] on
  /// invalid characters or an invalid length (Base45 groups are 3 chars
  /// per 2 bytes, with a final group of exactly 2 chars for a trailing
  /// single byte - a final group of 1 or a value that doesn't fit is
  /// malformed).
  static List<int> decode(String text) {
    final out = <int>[];
    for (var i = 0; i < text.length; i += 3) {
      final remaining = text.length - i;
      if (remaining == 1) {
        throw FormatException('Invalid Base45 length: dangling single character', text, i);
      } else if (remaining == 2) {
        final c = _valueOf(text, i);
        final d = _valueOf(text, i + 1);
        final n = c + d * 45;
        if (n > 255) {
          throw FormatException('Invalid Base45 trailing group: value $n exceeds a single byte', text, i);
        }
        out.add(n);
      } else {
        final c = _valueOf(text, i);
        final d = _valueOf(text, i + 1);
        final e = _valueOf(text, i + 2);
        final n = c + d * 45 + e * 45 * 45;
        if (n > 65535) {
          throw FormatException('Invalid Base45 group: value $n exceeds two bytes', text, i);
        }
        out.add(n ~/ 256);
        out.add(n % 256);
      }
    }
    return out;
  }

  static int _valueOf(String text, int index) {
    final char = text[index];
    final value = _alphabet.indexOf(char);
    if (value == -1) {
      throw FormatException('Invalid Base45 character: "$char"', text, index);
    }
    return value;
  }
}
