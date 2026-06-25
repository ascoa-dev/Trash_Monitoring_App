# Home Module Guide

This guide explains how the Home module is structured, how data flows through it, and how to extend it safely.

## Overview

The Home module renders the dashboard landing page with:

- A hero section (welcome + header artwork)
- A "Start New Cleanup" card
- Stats placeholders
- A Highlights carousel
- A horizontally scrolling News rail powered by WordPress posts
- A Blog CTA card and decorative bottom graphic

The layout is driven by AppDimensions tokens and applied responsively using SizeUtils.

## Folder structure

````plaintext
lib/modules/home/
```text
├─ bindings/
│  └─ home_binding.dart          # Registers controllers lazily (GetX)
├─ controller/
│  └─ posts_controller.dart      # Fetches & caches posts, exposes Rx state
├─ services/
│  └─ api_service.dart           # WordPress API client for posts/media
├─ views/
│  └─ home_screen.dart           # Screen composition
└─ widgets/
   ├─ home_news_card.dart        # News list item (asset/network image)
   └─ news_skeleton_card.dart    # Animated loading placeholder for news
````

## Data and state flow

- Binding: `HomeBinding` registers the `HomePostsController` lazily with a tag `home_posts` and `fenix: true`.
  - `fenix: true` lets GetX recreate the controller after it is disposed when navigating between tabs.
  - The binding is executed in `MainScreen.initState()`:
    - `HomeBinding().dependencies()`
- Controller: `HomePostsController`

  - State: `posts` (RxList&lt;Post&gt;), `isLoading` (RxBool), `error` (RxnString)
  - Lifecycle: On `onInit()`, it attempts to load cached posts from Hive for instant UI.
  - Loading: `loadPosts(perPage: 10)`
    1. Calls `ApiService.fetchPosts()` for minimal fields (id/title/link/featured_media)
    2. Deduplicates `featured_media` IDs and fetches media details in parallel using `ApiService.fetchMedia()`
    3. Assigns `imageUrl` into each `Post` where available
    4. Updates `posts` and persists to Hive for offline/fast warm-starts
  - Caching: Uses Hive box `home_posts_cache` to store the current list; writes replace the previous cache.

- Services: `ApiService`

  - Base URL: `https://ascoa-cm.org`
  - `fetchPosts({perPage})` → `List<Post>` — `/wp-json/wp/v2/posts?per_page=...&_fields=id,title,link,featured_media`
  - `fetchMedia(id)` → `MediaModel` — `/wp-json/wp/v2/media/{id}`; resolves a useful `source_url` with fallbacks

- Models:
  - `Post` (`lib/app/models/post.dart`) is a Hive type (typeId 10) that carries post metadata plus a transient `imageUrl`.
  - `MediaModel` (`lib/app/models/media.dart`) extracts an image URL from WP media JSON.
  - The generated adapter `post.g.dart` is created with `build_runner` and registered in `main.dart`.

## UI composition (`HomeScreen`)

- Layout uses tokens from `AppDimensions` and applies them with `SizeUtils.h/w/r`.
- Sections:
  - Hero: top artwork (`AppImages.dashboardTop`) and a centered welcome line using the `AuthController`'s `currentUserModel`.
  - Start Cleanup: Card with `PrimaryButton` that navigates to the Start Cleanup flow.
  - Stats: Placeholder labels for monthly cleanups and kg collected (replace with live data when available).
  - Highlights: Carousel with 3 placeholder items and a `PageController` (viewport fraction from tokens).
  - News:
    - Uses `Obx` to react to `HomePostsController` state.
    - While loading and no cache → renders `NewsSkeletonCard` list.
    - On error and empty cache → renders a retry affordance.
    - On success → renders a horizontal `ListView.separated` of `HomeNewsCard`.
    - `HomeNewsCard` opens the post link in the external browser via `url_launcher`.
    - Images use `CachedNetworkImage` with a soft placeholder color token.
  - Blog: CTA card; currently shows a "Coming Soon" snackbar.
  - Bottom graphic: decorative image anchored to the bottom (`AppImages.dashboardBottom`).

## Dependencies

Declared in `pubspec.yaml` and already integrated:

- `http` — WordPress REST calls
- `cached_network_image` — network image with caching and placeholders
- `url_launcher` — opens news links externally
- `hive` / `hive_flutter` — local caching of posts

Adapter registration (in `main.dart`):

```dart
await Hive.initFlutter();
Hive.registerAdapter(PostAdapter());
```

## Design tokens used

- `AppImages`: `dashboardTop`, `dashboardBottom`, `placeholder`, `cleanup`, `blog`
- `AppDimensions` (selection):
  - `homeScreenWelcomeTop`, `homeScreenHeaderTop`, `homeScreenHeaderHeight`, `homeScreenSpacer`
  - `homeScreenStartCleanup*` tokens for the card and button
  - `homeScreenHighlight*` tokens for the carousel and cards
  - `newsCard*` and `homeScreenNews*` for the News rail
  - `homeScreenBlogCard*`, `homeScreenBottomGraphicHeight`
- `AppTextStyles`: `dashboardGreeting`, `dashboardHeading`, `newsBody`, `newsCaption`, `blogText`, `cleanUpSubtitle`
- `AppColors`: `background`, `cardBackground`, `skeletonBase`/`skeletonHighlight`/`skeletonShade`, `newsCardPlaceholder`

## Navigation

- The Home screen is rendered inside `MainScreen` (see `lib/modules/main/views/main_screen.dart`).
- `MainScreen` initializes `HomeBinding` in `initState()` and manages the bottom navigation.
- Route: `AppRoutes.home` maps to `MainScreen` (not directly to `HomeScreen`).

## Extending the module

- Add more sections: follow the token + SizeUtils pattern for dimensions. Add new semantic tokens to `app_dimensions.dart` if needed.
- News list count: pass a different `perPage` to `loadPosts()` from the controller if you want more/less items for larger screens.
- Error/empty states: adjust copy or styling in the News section as required.
- Caching policy: switch to a time-based invalidation by storing a `lastFetchedAt` field in Hive if needed.
- Accessibility: ensure images and tappable elements provide proper semantics.

## Testing tips

- Unit test `HomePostsController` by mocking `ApiService` (e.g. with Mockito) and verifying:

  - Deduplication of media IDs and parallel fetching
  - Correct `imageUrl` assignment
  - Error propagation and recovery on retry
  - Cache read/write behavior (consider using a temporary Hive directory in tests)

- Widget test `HomeScreen` for:
  - Skeleton vs list rendering based on controller state
  - Tap on `HomeNewsCard` calls `launchUrl` with the expected link
  - Responsive sizing holds within tolerances when `MediaQuery` changes

## Troubleshooting

- If network images do not show, verify `http` responses and confirm `MediaModel` can resolve `source_url` (check WP media JSON structure).
- If controller lookup fails, confirm `MainScreen` calls `HomeBinding().dependencies()` and `Get.find<HomePostsController>(tag: 'home_posts')` is used in `HomeScreen`.
- If assets do not render, ensure paths are present in `pubspec.yaml` and referenced via `AppImages`.
