# Personal home (kbots fork)

Extra Discover / Projectivity features that stay on this fork’s **`cursor/personal-home-*`** branches (and eventually a `personal` release line). They are not aimed at upstream `edde746/plezy`.

## What this adds

1. **Library copy preference** (Settings → Appearance → Home Screen)  
   When both Jellyfin and Plex have a title: prefer **Jellyfin** (default), **Plex**, or **highest resolution**.  
   Applies to Continue Watching auto-pick, catalog match sort, deep links (`plezy://play?type=…&tmdb=…`).

2. **Discover rails** (Trakt; skipped if Trakt is disconnected)  
   - **Based on Your Watching** — Trakt recommendations (movies + shows interleaved)  
   - **Trending** — Trakt trending (movies + shows interleaved)

3. **Projectivity Preview Channels** for those same rails (`personal_based_on_watching`, `personal_trending`), deep-linking through the shared catalog play path.

4. **Curated Discover only** (optional) — hide noisy multi-server hubs; keep personal rails + recently added / new releases style rows.

## Settings toggles

| Pref | Default |
|---|---|
| `library_copy_preference` | jellyfin |
| `show_personal_based_on_watching` | true |
| `show_personal_trending` | true |
| `sync_personal_channels_to_launcher` | true |
| `discover_curated_rows_only` | false |

## Code map

- `lib/media/library_copy_preference.dart` + `media_item_merge.dart`
- `lib/services/personal_home/personal_home_feeds.dart`
- `lib/providers/discover_provider.dart` (prepends personal hubs)
- `lib/services/system_shelf_service.dart` (`syncPersonalHomeChannels`)
- Android: `PreviewChannelPublisher.kt` `ACTIVE_CHANNELS`

## Working rule

Ship these on personal branches. Keep `main` aligned with fork CI; open PRs against upstream only for fixes that belong upstream (Preview Channels artwork, etc.).
