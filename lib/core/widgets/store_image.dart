import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';

/// Reusable widget to display a store/customer thumbnail.
///
/// Priority:
///   1. [localPath] — file local (foto baru ditambah saat offline, belum sync)
///   2. [url] — server URL via CachedNetworkImage (tersimpan di cache lokal)
///   3. Placeholder ikon — jika keduanya null atau gagal load
///
/// Cache dari server tersimpan permanen di device — tetap tampil saat offline.
class StoreImage extends StatelessWidget {
  final String? url;
  final String? localPath; // path file lokal untuk data offline
  final double width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final double fallbackIconSize;
  final Color? fallbackBgColor;

  const StoreImage({
    super.key,
    required this.url,
    this.localPath,
    this.width = 80,
    this.height = 80,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.store,
    this.fallbackIconSize = 32,
    this.fallbackBgColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = _buildImage();

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }

  Widget _buildImage() {
    final double? resolvedHeight = (height != null && height!.isFinite)
        ? height
        : null;

    final placeholder = Container(
      width: width,
      height: resolvedHeight,
      decoration: BoxDecoration(
        color: fallbackBgColor ?? Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          color: Colors.grey[400],
          size: fallbackIconSize,
        ),
      ),
    );

    // 1. Prioritas: foto lokal (data offline belum sync)
    if (localPath != null) {
      final file = File(localPath!);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              file,
              width: width,
              height: resolvedHeight,
              fit: fit,
              errorBuilder: (context, error, stackTrace) => placeholder,
            );
          }
          return placeholder;
        },
      );
    }

    // 2. Server URL via CachedNetworkImage
    final resolvedUrl = ApiConstants.resolveImageUrl(url);
    if (resolvedUrl == null) return placeholder;

    return CachedNetworkImage(
      imageUrl: resolvedUrl,
      width: width,
      height: resolvedHeight,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: resolvedHeight,
        color: fallbackBgColor ?? Colors.grey[100],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => placeholder,
    );
  }
}
