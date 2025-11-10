import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ascoa_app/app/models/post.dart';
import 'package:ascoa_app/modules/home/services/api_service.dart';

class HomePostsController extends GetxController {
  final RxList<Post> posts = <Post>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  static const String _cacheBoxName = 'home_posts_cache';

  @override
  void onInit() {
    super.onInit();
    _loadFromCache();
  }

  /// Load posts from cache first (instant), then fetch fresh data
  Future<void> _loadFromCache() async {
    try {
      final box = await Hive.openBox<Post>(_cacheBoxName);
      final cachedPosts = box.values.toList();
      if (cachedPosts.isNotEmpty) {
        posts.assignAll(cachedPosts);
      }
    } catch (e) {
      // Cache read failed, continue to network fetch
    }
  }

  /// Load posts and their media efficiently (deduplicate media requests)
  Future<void> loadPosts({int perPage = 10}) async {
    try {
      isLoading.value = true;
      error.value = null;
      final fetched = await ApiService.fetchPosts(perPage: perPage);

      // collect unique media ids to avoid duplicate network requests
      final mediaIds =
          fetched
              .map((p) => p.featuredMedia)
              .where((id) => id != 0)
              .toSet()
              .toList();

      // fetch all media in parallel
      final Map<int, String> mediaMap = {};
      if (mediaIds.isNotEmpty) {
        final futures = mediaIds.map((id) async {
          final media = await ApiService.fetchMedia(id);
          mediaMap[id] = media.sourceUrl;
        });
        await Future.wait(futures);
      }

      // assign imageUrl from mediaMap when available
      for (final p in fetched) {
        if (p.featuredMedia != 0 && mediaMap.containsKey(p.featuredMedia)) {
          p.imageUrl = mediaMap[p.featuredMedia];
        }
      }

      posts.assignAll(fetched);

      // Cache the fetched posts
      await _cacheToHive(fetched);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Save posts to Hive for offline access
  Future<void> _cacheToHive(List<Post> newPosts) async {
    try {
      final box = await Hive.openBox<Post>(_cacheBoxName);
      await box.clear();
      for (final post in newPosts) {
        await box.add(post);
      }
    } catch (e) {
      // Cache write failed, non-fatal
    }
  }
}
