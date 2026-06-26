import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:we_monitor/app/models/post.dart';
import 'package:we_monitor/modules/home/services/api_service.dart';
import 'package:we_monitor/shared/analytics/analytics_service.dart';

class HomePostsController extends GetxController {
  final RxList<Post> posts = <Post>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  static const String _cacheBoxName = 'home_posts_cache';

  bool _isNetworkFetched = false;

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  Future<void> _initData() async {
    await _loadFromCache();
    await loadPosts();
  }

  /// Load posts from cache first (instant), then fetch fresh data
  Future<void> _loadFromCache() async {
    try {
      final box = await Hive.openBox<Post>(_cacheBoxName);
      final cachedPosts = box.values.toList();
      if (cachedPosts.isNotEmpty && !_isNetworkFetched) {
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

      _isNetworkFetched = true;
      posts.assignAll(fetched);
      Analytics.track(AnalyticsEvents.newsCarouselLoaded, {
        AnalyticsProps.cleanupsCount: fetched.length,
      });

      // Cache the fetched posts
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
