import 'media_backend.dart';

/// How Plezy picks among several library copies of one title (Continue
/// Watching, catalog play, deep links, chooser sort order).
///
/// Personal-home default is [jellyfin]: the local server wins when both
/// Jellyfin and Plex hold the title. [highestResolution] keeps the upstream
/// resolution-first order.
enum LibraryCopyPreference {
  /// Prefer Jellyfin copies, then Plex, then Emby; resolution breaks ties.
  jellyfin,

  /// Prefer Plex copies, then Jellyfin, then Emby; resolution breaks ties.
  plex,

  /// Ignore backend; tallest reported version wins (upstream behaviour).
  highestResolution,
}

extension LibraryCopyPreferenceRanking on LibraryCopyPreference {
  /// Lower is better. Used only when this preference is not
  /// [LibraryCopyPreference.highestResolution].
  int backendRank(MediaBackend backend) => switch (this) {
    LibraryCopyPreference.jellyfin => switch (backend) {
      MediaBackend.jellyfin => 0,
      MediaBackend.plex => 1,
      MediaBackend.emby => 2,
    },
    LibraryCopyPreference.plex => switch (backend) {
      MediaBackend.plex => 0,
      MediaBackend.jellyfin => 1,
      MediaBackend.emby => 2,
    },
    LibraryCopyPreference.highestResolution => 0,
  };

  /// True when activation should auto-open the best-sorted copy instead of
  /// showing the multi-copy picker.
  bool get autoPicksBestCopy => this != LibraryCopyPreference.highestResolution;
}

/// Active preference, or [LibraryCopyPreference.jellyfin] when settings are
/// unavailable (personal-home default).
LibraryCopyPreference resolveLibraryCopyPreference(LibraryCopyPreference? fromSettings) =>
    fromSettings ?? LibraryCopyPreference.jellyfin;
