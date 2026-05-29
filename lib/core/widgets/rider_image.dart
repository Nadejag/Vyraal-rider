import 'dart:convert' as convert;
import 'dart:typed_data';

import 'package:flutter/material.dart';

class RiderImage extends StatelessWidget {
  const RiderImage({
    required this.fallback,
    this.url,
    this.base64,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    super.key,
  });

  final String? url;
  final String? base64;
  final Widget fallback;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeImageBytes(base64) ?? _decodeImageBytes(url);
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    final imageUrl = _networkUrl(url);
    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return fallback;
        },
      );
    }

    return fallback;
  }

  static String? _networkUrl(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    if (text.startsWith('http://') || text.startsWith('https://')) return text;
    return null;
  }

  static Uint8List? _decodeImageBytes(String? value) {
    var text = value?.trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    final comma = text.indexOf(',');
    if (text.startsWith('data:image') && comma != -1) {
      text = text.substring(comma + 1);
    }
    if (text.startsWith('http://') || text.startsWith('https://')) return null;
    if (text.length < 32) return null;
    try {
      final normalized = convert.base64.normalize(
        text.replaceAll(RegExp(r'\s+'), ''),
      );
      return convert.base64Decode(normalized);
    } catch (_) {
      return null;
    }
  }
}
