import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ascoa_app/app/models/post.dart';
import 'package:ascoa_app/modules/home/services/api_service.dart';
import 'package:ascoa_app/shared/analytics/analytics_service.dart';

/// Backs the News tab: the full blog feed, vertically stacked.
///
/// Lazy by design — nothing is fetched until [loadOnce] is called the first
/// time the user opens the News tab (see MainScreen). Cache-first so a return
/// visit paints instantly from Hive before the network refresh lands.
class NewsPostsController extends GetxController {
  final RxList<Post> posts = <Post>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  static const String _cacheBoxName = 'news_posts_cache';

  // ponytail: single batch capped at 50, not true pagination. Add infinite
  // scroll if the blog grows past ~50 posts.
  static const int _perPage = 50;

  bool _started = false;

  /// Fetch the feed the first time the News tab is shown. No-op afterwards.
  Future<void> loadOnce() async {
    if (_started) return;
    _started = true;
    await _loadFromCache();
    await loadPosts();
  }

  Future<void> _loadFromCache() async {
    try {
      final box = await Hive.openBox<Post>(_cacheBoxName);
      final cached = box.values.toList();
      if (cached.isNotEmpty) posts.assignAll(cached);
    } catch (e) {
      // Cache read failed, fall through to network.
    }
  }

  Future<void> loadPosts() async {
    try {
      isLoading.value = true;
      error.value = null;
      final fetched = await ApiService.fetchPosts(perPage: _perPage);
      posts.assignAll(fetched);
      await _cacheToHive(fetched);
    } catch (e) {
      Analytics.track(AnalyticsEvents.newsFetchFailed, {
        AnalyticsProps.reason: e.toString(),
      });
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _cacheToHive(List<Post> newPosts) async {
    try {
      final box = await Hive.openBox<Post>(_cacheBoxName);
      await box.clear();
      for (final post in newPosts) {
        await box.add(post);
      }
    } catch (e) {
      // Cache write failed, non-fatal.
    }
  }
}
