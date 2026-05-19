import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CachedTileProvider
//
// Custom TileProvider untuk flutter_map yang menyimpan tile OpenStreetMap
// ke cache disk via flutter_cache_manager (MIT license).
//
// Tile yang pernah dimuat akan tersimpan di cache dan dapat ditampilkan
// kembali saat offline, tanpa memerlukan flutter_map_tile_caching (GPL).
//
// Cara pakai di TileLayer:
//   tileProvider: CachedTileProvider(),
// ─────────────────────────────────────────────────────────────────────────────

/// Cache manager khusus untuk tile peta.
/// Menyimpan tile lebih lama (30 hari) agar tersedia saat offline.
class MapTileCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'mapTileCache';

  static final MapTileCacheManager _instance = MapTileCacheManager._();
  factory MapTileCacheManager() => _instance;

  MapTileCacheManager._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 5000, // max 5000 tiles tersimpan
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ),
      );
}

/// TileProvider yang menggunakan [MapTileCacheManager] untuk cache disk.
class CachedTileProvider extends TileProvider {
  final CacheManager cacheManager;

  CachedTileProvider({CacheManager? cacheManager})
    : cacheManager = cacheManager ?? MapTileCacheManager();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return _CachedNetworkImageProvider(url, cacheManager: cacheManager);
  }
}

// ── Private: ImageProvider backed by CacheManager ─────────────────────────

class _CachedNetworkImageProvider
    extends ImageProvider<_CachedNetworkImageProvider> {
  final String url;
  final CacheManager cacheManager;

  const _CachedNetworkImageProvider(this.url, {required this.cacheManager});

  @override
  Future<_CachedNetworkImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _CachedNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      informationCollector: () => [DiagnosticsProperty('URL', url)],
    );
  }

  Future<Codec> _loadAsync(
    _CachedNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    try {
      // Coba ambil dari cache dulu, kalau tidak ada baru download
      final file = await cacheManager.getSingleFile(
        key.url,
        headers: const {'User-Agent': 'com.sales_tracker.mobile'},
      );
      final bytes = await file.readAsBytes();
      final buffer = await ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    } catch (e) {
      // Kalau offline dan tidak ada cache → rethrow (tile blank)
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _CachedNetworkImageProvider && url == other.url;

  @override
  int get hashCode => url.hashCode;
}
