import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class RiderPickedImage {
  const RiderPickedImage({
    required this.fileName,
    required this.mimeType,
    required this.base64Data,
    required this.bytesLength,
  });

  final String fileName;
  final String mimeType;
  final String base64Data;
  final int bytesLength;

  String get dataUri => 'data:$mimeType;base64,$base64Data';
}

class RiderImageUploadService {
  RiderImageUploadService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<RiderPickedImage?> pickDocumentImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 72,
    double maxWidth = 1280,
    double maxHeight = 1280,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) return null;

    final mime = _mimeType(picked.name, bytes);
    return RiderPickedImage(
      fileName: picked.name,
      mimeType: mime,
      base64Data: base64Encode(bytes),
      bytesLength: bytes.length,
    );
  }

  String _mimeType(String name, Uint8List bytes) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (bytes.length > 3 && bytes[0] == 0x89 && bytes[1] == 0x50) return 'image/png';
    return 'image/jpeg';
  }
}
