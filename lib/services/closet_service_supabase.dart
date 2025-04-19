import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clothing_item.dart';
import './supabase_service.dart';

/// Supabaseを使用した衣類アイテム管理サービス
class ClosetServiceSupabase {
  static final ClosetServiceSupabase _instance = ClosetServiceSupabase._internal();
  
  factory ClosetServiceSupabase() {
    return _instance;
  }
  
  ClosetServiceSupabase._internal();
  
  final SupabaseService _supabaseService = SupabaseService();
  List<ClothingItem> _cachedItems = [];
  bool _initialized = false;
  
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    
    await loadItems();
    _initialized = true;
  }
  
  /// Supabaseからすべてのアイテムを読み込む
  Future<void> loadItems() async {
    // Supabase からの取得 (エラー時は空リスト)
    try {
      final itemsData = await _supabaseService.getAllClothingItems();
      _cachedItems = itemsData.map((data) => ClothingItem.fromSupabase(data)).toList();
    } catch (e) {
      print('Error loading items from Supabase: $e');
      _cachedItems = [];
    }
    // 常にサンプルアイテムを重複なく追加
    final sampleItems = <ClothingItem>[
      ClothingItem(
        name: 'エアリズムコットンT',
        category: 'Tシャツ',
        color: '白',
        brand: 'ユニクロ',
        imageUrl: 'https://picsum.photos/seed/airism/400/400',
      ),
      ClothingItem(
        name: 'ウルトラライトダウンジャケット',
        category: 'アウター',
        color: 'ネイビー',
        brand: 'ユニクロ',
        imageUrl: 'https://picsum.photos/seed/downjacket/400/400',
      ),
      ClothingItem(
        name: 'スーピマコットンオーバーサイズT',
        category: 'Tシャツ',
        color: '黒',
        brand: 'ユニクロ',
        imageUrl: 'https://picsum.photos/seed/oversizet/400/400',
      ),
      ClothingItem(
        name: 'ストレートジーンズ',
        category: 'パンツ',
        color: 'インディゴ',
        brand: 'ユニクロ',
        imageUrl: 'https://picsum.photos/seed/jeans/400/400',
      ),
    ];
    for (final sample in sampleItems) {
      if (!_cachedItems.any((item) => item.name == sample.name)) {
        _cachedItems.add(sample);
      }
    }
    // ローカルにバックアップ
    await _saveToLocalStorage();
  }
  
  /// ローカルストレージにアイテムを保存（バックアップ）
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = _cachedItems
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      
      await prefs.setStringList('clothing_items', itemsJson);
    } catch (e) {
      print('Error saving items to local storage: $e');
    }
  }
  
  /// すべてのアイテムを取得
  Future<List<ClothingItem>> getAllItems() async {
    await _ensureInitialized();
    return [..._cachedItems];
  }
  
  /// アイテムを追加
  Future<ClothingItem> addItem(ClothingItem item) async {
    await _ensureInitialized();
    
    try {
      // Supabaseにアイテムを追加
      final result = await _supabaseService.addClothingItem(item.toJson());
      final newItem = ClothingItem.fromSupabase(result);
      
      // キャッシュを更新
      _cachedItems.add(newItem);
      
      // バックアップとしてローカルストレージにも保存
      await _saveToLocalStorage();
      
      return newItem;
    } catch (e) {
      print('Error adding item to Supabase: $e');
      throw Exception('アイテムの追加に失敗しました');
    }
  }
  
  /// アイテムを更新
  Future<void> updateItem(ClothingItem updatedItem) async {
    await _ensureInitialized();
    
    try {
      // Supabaseでアイテムを更新
      await _supabaseService.updateClothingItem(updatedItem.id, updatedItem.toJson());
      
      // キャッシュを更新
      final index = _cachedItems.indexWhere((item) => item.id == updatedItem.id);
      if (index != -1) {
        _cachedItems[index] = updatedItem;
      }
      
      // バックアップとしてローカルストレージにも保存
      await _saveToLocalStorage();
    } catch (e) {
      print('Error updating item in Supabase: $e');
      throw Exception('アイテムの更新に失敗しました');
    }
  }
  
  /// アイテムを削除
  Future<void> removeItem(String id) async {
    await _ensureInitialized();
    
    try {
      // Supabaseからアイテムを削除
      await _supabaseService.deleteClothingItem(id);
      
      // キャッシュを更新
      _cachedItems.removeWhere((item) => item.id == id);
      
      // バックアップとしてローカルストレージにも保存
      await _saveToLocalStorage();
    } catch (e) {
      print('Error removing item from Supabase: $e');
      throw Exception('アイテムの削除に失敗しました');
    }
  }
  
  /// カテゴリでアイテムを検索
  Future<List<ClothingItem>> getItemsByCategory(String category) async {
    await _ensureInitialized();
    return _cachedItems.where((item) => item.category == category).toList();
  }
  
  /// 色でアイテムを検索
  Future<List<ClothingItem>> getItemsByColor(String color) async {
    await _ensureInitialized();
    return _cachedItems.where((item) => item.color == color).toList();
  }
  
  /// IDからアイテムを取得
  Future<ClothingItem?> getItemById(String id) async {
    await _ensureInitialized();
    
    try {
      // まずキャッシュを確認
      final cachedItem = _cachedItems.firstWhere((item) => item.id == id, orElse: () => throw Exception());
      return cachedItem;
    } catch (_) {
      try {
        // キャッシュになければSupabaseから取得
        final itemData = await _supabaseService.getClothingItemById(id);
        if (itemData != null) {
          final item = ClothingItem.fromSupabase(itemData);
          
          // キャッシュを更新
          _cachedItems.add(item);
          return item;
        }
      } catch (e) {
        print('Error getting item by ID from Supabase: $e');
      }
      return null;
    }
  }
  
  /// 複数のIDからアイテムのリストを取得
  Future<List<ClothingItem>> getItemsByIds(List<String> ids) async {
    await _ensureInitialized();
    
    final items = <ClothingItem>[];
    for (final id in ids) {
      final item = await getItemById(id);
      if (item != null) {
        items.add(item);
      }
    }
    return items;
  }
  
  /// アイテムを着用済みとしてマーク
  Future<void> markItemAsWorn(String id) async {
    await _ensureInitialized();
    
    try {
      // Supabaseで着用回数を増やす
      await _supabaseService.incrementWearCount(id);
      
      // キャッシュを更新
      final item = await getItemById(id);
      if (item != null) {
        final updatedItem = item.markAsWorn();
        final index = _cachedItems.indexWhere((item) => item.id == id);
        if (index != -1) {
          _cachedItems[index] = updatedItem;
        }
      }
      
      // バックアップとしてローカルストレージにも保存
      await _saveToLocalStorage();
    } catch (e) {
      print('Error marking item as worn in Supabase: $e');
      throw Exception('アイテムの着用記録に失敗しました');
    }
  }
  
  /// 着用回数でソートされたアイテムを取得
  Future<List<ClothingItem>> getMostWornItems({int limit = 5}) async {
    await _ensureInitialized();
    final sortedItems = [..._cachedItems]..sort((a, b) => b.wearCount.compareTo(a.wearCount));
    return sortedItems.take(limit).toList();
  }
  
  /// 最近追加されたアイテムを取得
  Future<List<ClothingItem>> getRecentItems({int limit = 5}) async {
    await _ensureInitialized();
    final sortedItems = [..._cachedItems]..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return sortedItems.take(limit).toList();
  }
}
