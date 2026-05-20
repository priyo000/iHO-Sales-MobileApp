import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  ImagePickerService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage({
    required BuildContext context,
    int imageQuality = 80,
    double? maxWidth = 1280,
    double? maxHeight = 1280,
  }) async {
    final source = await _showSourceSheet(context);
    if (source == null) return null;
    return _pickFromSource(
      source,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  static Future<File?> pickFromCamera({
    int imageQuality = 80,
    double? maxWidth = 1280,
    double? maxHeight = 1280,
  }) {
    return _pickFromSource(
      ImageSource.camera,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  static Future<File?> pickFromGallery({
    int imageQuality = 80,
    double? maxWidth = 1280,
    double? maxHeight = 1280,
  }) {
    return _pickFromSource(
      ImageSource.gallery,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  static Future<File?> _pickFromSource(
    ImageSource source, {
    required int imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  static Future<ImageSource?> _showSourceSheet(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil Foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
