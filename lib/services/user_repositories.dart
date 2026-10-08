import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/storage_keys.dart';
import '../core/storage/local_storage.dart';
import '../models/favorite_item.dart';
import '../models/search_history_item.dart';
import '../models/search_response.dart';
import '../models/search_result.dart';
import '../models/user_models.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(localStorageProvider));
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(localStorageProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(localStorageProvider));
});

class HistoryRepository {
  HistoryRepository(this._storage);

  final LocalStorage _storage;

  Future<List<SearchHistoryItem>> list() async {
    return _storage
        .readJsonList(StorageKeys.localHistory)
        .map(SearchHistoryItem.fromJson)
        .toList();
  }

  Future<void> saveLocal(SearchHistoryItem item) async {
    final current = _storage.readJsonList(StorageKeys.localHistory);
    current.removeWhere((e) => e['id'] == item.id);
    current.insert(0, item.toJson());
    await _storage.writeJsonList(StorageKeys.localHistory, current.take(50).toList());
  }

  Future<void> saveResponse(SearchResponse response) async {
    final cache = _storage.readJsonList(StorageKeys.localSearchCache);
    cache.removeWhere((e) => e['searchId'] == response.searchId);
    cache.insert(0, response.toJson());
    await _storage.writeJsonList(StorageKeys.localSearchCache, cache.take(20).toList());
  }

  SearchResponse? getCached(String id) {
    final cache = _storage.readJsonList(StorageKeys.localSearchCache);
    for (final item in cache) {
      if (item['searchId']?.toString() == id) {
        return SearchResponse.fromJson(item);
      }
    }
    return null;
  }

  Future<void> delete(String id) async {
    final current = _storage.readJsonList(StorageKeys.localHistory)
      ..removeWhere((e) => e['id'] == id);
    await _storage.writeJsonList(StorageKeys.localHistory, current);
  }

  Future<void> clear() async {
    await _storage.writeJsonList(StorageKeys.localHistory, []);
    await _storage.writeJsonList(StorageKeys.localSearchCache, []);
    await _storage.writeJsonList(StorageKeys.recentSearches, []);
  }
}

class FavoritesRepository {
  FavoritesRepository(this._storage);

  final LocalStorage _storage;

  Future<List<FavoriteItem>> list() async {
    return _storage
        .readJsonList(StorageKeys.localFavorites)
        .map(FavoriteItem.fromJson)
        .toList();
  }

  Future<void> add(SearchResult result) async {
    final key = result.favoriteId;
    final current = _storage.readJsonList(StorageKeys.localFavorites);
    current.removeWhere(
      (e) =>
          e['id'] == key ||
          e['result']?['id'] == result.id ||
          e['result']?['favoriteId'] == key,
    );
    current.insert(
      0,
      FavoriteItem(id: key, result: result, createdAt: DateTime.now()).toJson(),
    );
    await _storage.writeJsonList(StorageKeys.localFavorites, current);
  }

  Future<void> remove(String id) async {
    final current = _storage.readJsonList(StorageKeys.localFavorites)
      ..removeWhere((e) => e['id'] == id || e['result']?['id'] == id);
    await _storage.writeJsonList(StorageKeys.localFavorites, current);
  }

  Future<void> removeResult(SearchResult result) => remove(result.favoriteId);

  bool isFavoriteResult(SearchResult result) => isFavorite(result.favoriteId);

  bool isFavorite(String id) {
    return _storage.readJsonList(StorageKeys.localFavorites).any(
          (e) => e['id'] == id || e['result']?['id'] == id,
        );
  }
}

class UserRepository {
  UserRepository(this._storage);

  final LocalStorage _storage;

  Future<UserProfile?> profile() async => null;

  Future<UsageStats> usage() async {
    await _storage.refreshSubscriptionState();
    return _storage.buildUsageStats();
  }

  Future<SubscriptionInfo> subscription() async {
    await _storage.refreshSubscriptionState();
    return _storage.buildSubscriptionInfo();
  }

  Future<SubscriptionInfo> verify(Map<String, dynamic> payload) async {
    final productId =
        payload['productId']?.toString() ?? AppConstants.weeklyProductId;
    await _storage.activateSubscriptionFromPurchase(
      productId: productId,
      restored: payload['restored'] == true,
    );
    return subscription();
  }

  Future<void> deleteAccount() async {}
}
