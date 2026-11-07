import 'package:flutter/foundation.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_hub.dart';
import '../../media/media_item.dart';
import '../../models/catalog/catalog_item.dart';
import '../../providers/catalog_sources_provider.dart';
import '../../utils/app_logger.dart';
import '../catalog/catalog_source.dart';
import '../settings_service.dart';

/// Stable hub / Preview Channel keys for the personal-home rails.
abstract final class PersonalHomeChannelKeys {
  static const basedOnWatching = 'personal_based_on_watching';
  static const trending = 'personal_trending';

  static const all = <String>[basedOnWatching, trending];
}

/// Builds Discover / Projectivity rails that are personal to this fork:
/// Trakt "Based on your watching" (recommendations) and Trending.
///
/// Items are catalog stand-ins ([CatalogItem.toMediaItem]) so taps route
/// through the shared catalog open path (Jellyfin → Plex → request).
class PersonalHomeFeeds {
  PersonalHomeFeeds({required this.traktSource, this.rowLimit = 20});

  factory PersonalHomeFeeds.fromCatalogSources(CatalogSourcesProvider sources, {int rowLimit = 20}) {
    return PersonalHomeFeeds(
      traktSource: () {
        for (final source in sources.connectedSources) {
          if (source.id == CatalogSourceId.trakt) return source;
        }
        return null;
      },
      rowLimit: rowLimit,
    );
  }

  final CatalogSource? Function() traktSource;
  final int rowLimit;

  /// Hubs to prepend on Discover, honouring personal-home toggles.
  Future<List<MediaHub>> loadDiscoverHubs() async {
    final settings = SettingsService.instanceOrNull;
    final showBasedOn = settings?.read(SettingsService.showPersonalBasedOnWatching) ?? true;
    final showTrending = settings?.read(SettingsService.showPersonalTrending) ?? true;
    if (!showBasedOn && !showTrending) return const [];

    final source = traktSource();
    if (source == null) {
      appLogger.d('PersonalHomeFeeds: Trakt not connected; skipping personal rails');
      return const [];
    }

    final hubs = <MediaHub>[];
    if (showBasedOn) {
      final basedOn = await _basedOnWatching(source);
      if (basedOn != null) hubs.add(basedOn);
    }
    if (showTrending) {
      final trending = await _trending(source);
      if (trending != null) hubs.add(trending);
    }
    return hubs;
  }

  Future<MediaHub?> _basedOnWatching(CatalogSource source) async {
    try {
      final movies = await source.fetchRow(CatalogRowId.recommendedMovies, limit: rowLimit);
      final shows = await source.fetchRow(CatalogRowId.recommendedShows, limit: rowLimit);
      final items = _interleave(movies.items, shows.items).map(_toMedia).toList(growable: false);
      if (items.isEmpty) return null;
      return MediaHub(
        id: PersonalHomeChannelKeys.basedOnWatching,
        identifier: PersonalHomeChannelKeys.basedOnWatching,
        title: t.discover.personalBasedOnWatching,
        type: 'mixed',
        items: items,
        size: items.length,
      );
    } catch (e, stackTrace) {
      appLogger.w('PersonalHomeFeeds: based-on-watching failed', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<MediaHub?> _trending(CatalogSource source) async {
    try {
      final movies = await source.fetchRow(CatalogRowId.trendingMovies, limit: rowLimit);
      final shows = await source.fetchRow(CatalogRowId.trendingShows, limit: rowLimit);
      final items = _interleave(movies.items, shows.items).map(_toMedia).toList(growable: false);
      if (items.isEmpty) return null;
      return MediaHub(
        id: PersonalHomeChannelKeys.trending,
        identifier: PersonalHomeChannelKeys.trending,
        title: t.discover.personalTrending,
        type: 'mixed',
        items: items,
        size: items.length,
      );
    } catch (e, stackTrace) {
      appLogger.w('PersonalHomeFeeds: trending failed', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  static MediaItem _toMedia(CatalogItem item) => item.toMediaItem();

  /// Alternate movie/show so a mixed rail does not dump one kind first.
  static List<CatalogItem> _interleave(List<CatalogItem> a, List<CatalogItem> b) {
    final out = <CatalogItem>[];
    final max = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < max; i++) {
      if (i < a.length) out.add(a[i]);
      if (i < b.length) out.add(b[i]);
    }
    return out;
  }
}

/// Whether a Discover hub is one of the curated "clean home" rows.
bool isPersonalOrCuratedDiscoverHub(MediaHub hub) {
  final key = (hub.identifier ?? hub.id).toLowerCase();
  final compact = key.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  if (PersonalHomeChannelKeys.all.any((k) => compact.contains(k.replaceAll('_', '')))) {
    return true;
  }
  if (hub.isContinueWatchingHub) return true;
  if (compact.contains('recentlyadded') || compact.endsWith('recent')) return true;
  if (compact.contains('recentlyreleased') || compact.contains('newrelease') || compact.contains('premiere')) {
    return true;
  }
  if (compact.contains('latest') && !compact.contains('album')) return true;
  return false;
}

@visibleForTesting
List<MediaHub> filterCuratedDiscoverHubsForTest(List<MediaHub> hubs) =>
    hubs.where(isPersonalOrCuratedDiscoverHub).toList(growable: false);
