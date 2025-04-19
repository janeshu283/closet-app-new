import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/outfit.dart';
import '../models/clothing_item.dart';
import 'closet_service_supabase.dart';
import 'supabase_service.dart';

/// Supabaseを使用したコーディネートサービスクラス
class OutfitServiceSupabase {
  static const String _storageKey = 'outfits';
  List<Outfit> _cachedOutfits = [];
  bool _initialized = false;
  
  /// シングルトンインスタンス
  static final OutfitServiceSupabase _instance = OutfitServiceSupabase._internal();
  
  /// ファクトリーコンストラクタ
  factory OutfitServiceSupabase() {
    return _instance;
  }
  
  /// 内部コンストラクタ
  OutfitServiceSupabase._internal();
  
  final SupabaseService _supabaseService = SupabaseService();
  final ClosetServiceSupabase _closetService = ClosetServiceSupabase();
  
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    
    // SupabaseServiceの初期化は不要のため呼び出しを削除
    await loadOutfits();
    _initialized = true;
  }
  
  /// Supabaseからコーディネートを読み込む
  Future<void> loadOutfits() async {
    try {
      final outfitsData = await _supabaseService.getAllOutfits();
      _cachedOutfits = [];
      
      for (final outfitData in outfitsData) {
        final outfitItems = outfitData['outfit_items'] as List<dynamic>;
        _cachedOutfits.add(Outfit.fromSupabase(outfitData, outfitItems));
      }
    } catch (e) {
      print('Error loading outfits from Supabase: $e');
      _cachedOutfits = [];
      
      // フォールバック: ローカルストレージから読み込み
      await _loadFromLocalStorage();
    }
  }
  
  /// ローカルストレージからコーディネートを読み込む（フォールバック）
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final outfitsJson = prefs.getStringList(_storageKey) ?? [];
      
      _cachedOutfits = outfitsJson
          .map((json) => Outfit.fromMap(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Error loading outfits from local storage: $e');
      _cachedOutfits = [];
    }
  }
  
  /// ローカルストレージにコーディネートを保存（バックアップ）
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final outfitsJson = _cachedOutfits
          .map((outfit) => jsonEncode(outfit.toMap()))
          .toList();
      
      await prefs.setStringList(_storageKey, outfitsJson);
    } catch (e) {
      print('Error saving outfits to local storage: $e');
    }
  }
  
  /// すべてのコーディネートを取得
  Future<List<Outfit>> getAllOutfits() async {
    await _ensureInitialized();
    return [..._cachedOutfits];
  }
  
  /// 特定のアイテムを含むコーディネートを取得
  Future<List<Outfit>> getOutfitsContainingItem(String itemId) async {
    await _ensureInitialized();
    return _cachedOutfits.where((outfit) => outfit.itemIds.contains(itemId)).toList();
  }
  
  /// 季節別にコーディネートを取得
  Future<List<Outfit>> getOutfitsBySeason(String season) async {
    await _ensureInitialized();
    return _cachedOutfits.where((outfit) => outfit.season == season).toList();
  }
  
  /// 場面別にコーディネートを取得
  Future<List<Outfit>> getOutfitsByOccasion(String occasion) async {
    await _ensureInitialized();
    return _cachedOutfits.where((outfit) => outfit.occasion == occasion).toList();
  }
  
  /// コーディネートに含まれるアイテムを取得
  Future<List<ClothingItem>> getItemsInOutfit(Outfit outfit) async {
    return await _closetService.getItemsByIds(outfit.itemIds);
  }
  
  /// コーディネートを追加
  Future<Outfit> addOutfit(Outfit outfit) async {
    await _ensureInitialized();
    
    try {
      // Supabaseにコーディネートを追加
      final result = await _supabaseService.addOutfit(outfit.toSupabase(), outfit.itemIds);
      
      // 返されたデータからOutfitオブジェクトを作成
      final outfitItems = result['items'] as List<dynamic>;
      final newOutfit = Outfit(
        id: result['id'],
        name: result['name'],
        itemIds: outfitItems.map<String>((item) => item['clothing_item_id'] as String).toList(),
        createdAt: DateTime.parse(result['created_at']),
        lastWorn: result['last_worn'] != null ? DateTime.parse(result['last_worn']) : null,
        wearCount: result['wear_count'] ?? 0,
        description: result['description'],
        season: result['season'],
        occasion: result['occasion'],
        notes: result['notes'],
      );
      
      // キャッシュを更新
      _cachedOutfits.add(newOutfit);
      
      // バックアップとしてローカルストレージにも保存
      await _saveToLocalStorage();
      
      return newOutfit;
    } catch (e) {
      print('Error adding outfit to Supabase: $e');
      throw Exception('コーディネートの追加に失敗しました');
    }
  }
  
  /// コーディネートを更新
  Future<void> updateOutfit(Outfit updatedOutfit) async {
    await _ensureInitialized();
    
    try {
      // Supabaseでコーディネートを更新
      await _supabaseService.updateOutfit(
        updatedOutfit.id, 
        updatedOutfit.toSupabase(), 
        updatedOutfit.itemIds
      );
      
      // キャッシュを更新
      final index = _cachedOutfits.indexWhere((outfit) => outfit.id == updatedOutfit.id);
      if (index != -1) {
        _cachedOutfits[index] = updatedOutfit;
      }
      
      // バックアップとしてローカルストレージにも保存
      await _saveToLocalStorage();
    } catch (e) {
      print('Error updating outfit in Supabase: $e');
      throw Exception('コーディネートの更新に失敗しました');
    }
  }
  
  /// コーディネートを削除
  Future<void> removeOutfit(String id) async {
    await _ensureInitialized();
    
    try {
      // Supabaseからコーディネートを削除
      await _supabaseService.deleteOutfit(id);
      
      // キャッシュを更新
      _cachedOutfits.removeWhere((outfit) => outfit.id == id);
      
      // バックアップとしてローカルストレージにも保存
      await _saveToLocalStorage();
    } catch (e) {
      print('Error removing outfit from Supabase: $e');
      throw Exception('コーディネートの削除に失敗しました');
    }
  }
  
  /// コーディネートを着用済みとしてマーク
  Future<void> markOutfitAsWorn(String id) async {
    await _ensureInitialized();
    
    try {
      // Supabaseで着用回数を増やす
      await _supabaseService.incrementOutfitWearCount(id);
      
      // キャッシュを更新
      final index = _cachedOutfits.indexWhere((outfit) => outfit.id == id);
      if (index != -1) {
        _cachedOutfits[index] = _cachedOutfits[index].markAsWorn();
        
        // コーディネートに含まれる各アイテムも着用済みとしてマーク
        for (final itemId in _cachedOutfits[index].itemIds) {
          await _closetService.markItemAsWorn(itemId);
        }
      }
      
      // バックアップとしてローカルストレージにも保存
      await _saveToLocalStorage();
    } catch (e) {
      print('Error marking outfit as worn in Supabase: $e');
      throw Exception('コーディネートの着用記録に失敗しました');
    }
  }
  
  /// IDでコーディネートを取得
  Future<Outfit?> getOutfitById(String id) async {
    await _ensureInitialized();
    
    try {
      // まずキャッシュを確認
      final cachedOutfit = _cachedOutfits.firstWhere(
        (outfit) => outfit.id == id, 
        orElse: () => throw Exception()
      );
      return cachedOutfit;
    } catch (_) {
      try {
        // キャッシュになければSupabaseから取得
        final outfitData = await _supabaseService.getOutfitById(id);
        if (outfitData != null) {
          final outfitItems = outfitData['outfit_items'] as List<dynamic>;
          final outfit = Outfit.fromSupabase(outfitData, outfitItems);
          
          // キャッシュを更新
          _cachedOutfits.add(outfit);
          return outfit;
        }
      } catch (e) {
        print('Error getting outfit by ID from Supabase: $e');
      }
      return null;
    }
  }
  
  /// 最近作成されたコーディネートを取得
  Future<List<Outfit>> getRecentOutfits({int limit = 5}) async {
    await _ensureInitialized();
    final sortedOutfits = [..._cachedOutfits]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedOutfits.take(limit).toList();
  }
  
  /// 最もよく着用するコーディネートを取得
  Future<List<Outfit>> getMostWornOutfits({int limit = 5}) async {
    await _ensureInitialized();
    final sortedOutfits = [..._cachedOutfits]..sort((a, b) => b.wearCount.compareTo(a.wearCount));
    return sortedOutfits.take(limit).toList();
  }
  
  /// 天気に基づくコーディネート提案を取得
  Future<List<Outfit>> getWeatherBasedSuggestions(String condition, double temperature) async {
    await _ensureInitialized();
    
    try {
      final suggestions = await _supabaseService.getWeatherOutfitSuggestions(condition, temperature);
      
      final outfits = <Outfit>[];
      for (final suggestion in suggestions) {
        final outfitData = suggestion['outfits'];
        final outfitItems = outfitData['outfit_items'] as List<dynamic>;
        outfits.add(Outfit.fromSupabase(outfitData, outfitItems));
      }
      
      return outfits;
    } catch (e) {
      print('Error getting weather-based outfit suggestions: $e');
      
      // フォールバック: キャッシュから適切なコーディネートを探す
      return _findSuitableOutfitsForWeather(condition, temperature);
    }
  }
  
  /// 天気条件に合うコーディネートをキャッシュから探す（フォールバック）
  List<Outfit> _findSuitableOutfitsForWeather(String condition, double temperature) {
    String season;
    
    // 温度に基づいて季節を判断
    if (temperature >= 25) {
      season = '夏';
    } else if (temperature >= 15) {
      season = '春';
    } else if (temperature >= 5) {
      season = '秋';
    } else {
      season = '冬';
    }
    
    // 季節に合うコーディネートをフィルタリング
    return _cachedOutfits
        .where((outfit) => outfit.season == season || outfit.season == null)
        .take(3)
        .toList();
  }
}
