import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/outfit.dart';
import '../models/clothing_item.dart';
import 'closet_service.dart';

/// コーディネートサービスクラス
/// コーディネートの管理を担当
class OutfitService {
  static const String _storageKey = 'outfits';
  List<Outfit> _outfits = [];
  
  /// シングルトンインスタンス
  static final OutfitService _instance = OutfitService._internal();
  
  /// ファクトリーコンストラクタ
  factory OutfitService() {
    return _instance;
  }
  
  /// 内部コンストラクタ
  OutfitService._internal();
  
  /// 初期化処理
  Future<void> initialize() async {
    await _loadOutfits();
  }
  
  /// すべてのコーディネートを取得
  List<Outfit> getAllOutfits() {
    return [..._outfits];
  }
  
  /// 特定のアイテムを含むコーディネートを取得
  List<Outfit> getOutfitsContainingItem(int itemId) {
    return _outfits.where((outfit) => outfit.itemIds.contains(itemId)).toList();
  }
  
  /// 季節別にコーディネートを取得
  List<Outfit> getOutfitsBySeason(String season) {
    return _outfits.where((outfit) => outfit.season == season).toList();
  }
  
  /// 場面別にコーディネートを取得
  List<Outfit> getOutfitsByOccasion(String occasion) {
    return _outfits.where((outfit) => outfit.occasion == occasion).toList();
  }
  
  /// コーディネートに含まれるアイテムを取得
  List<ClothingItem> getItemsInOutfit(Outfit outfit) {
    final closetService = ClosetService();
    final allItems = closetService.getAllItems();
    return allItems.where((item) => outfit.itemIds.contains(item.id)).toList();
  }
  
  /// コーディネートを追加
  Future<void> addOutfit(Outfit outfit) async {
    _outfits.add(outfit);
    await _saveOutfits();
  }
  
  /// コーディネートを更新
  Future<void> updateOutfit(Outfit updatedOutfit) async {
    final index = _outfits.indexWhere((outfit) => outfit.id == updatedOutfit.id);
    if (index != -1) {
      _outfits[index] = updatedOutfit;
      await _saveOutfits();
    }
  }
  
  /// コーディネートを削除
  Future<void> removeOutfit(int id) async {
    _outfits.removeWhere((outfit) => outfit.id == id);
    await _saveOutfits();
  }
  
  /// コーディネートを着用済みとしてマーク
  Future<void> markOutfitAsWorn(int id) async {
    final index = _outfits.indexWhere((outfit) => outfit.id == id);
    if (index != -1) {
      _outfits[index] = _outfits[index].markAsWorn();
      
      // コーディネートに含まれる各アイテムも着用済みとしてマーク
      final closetService = ClosetService();
      for (final itemId in _outfits[index].itemIds) {
        await closetService.markItemAsWorn(itemId);
      }
      
      await _saveOutfits();
    }
  }
  
  /// 新しいコーディネートIDを生成
  int generateNewId() {
    return _outfits.isEmpty ? 1 : _outfits.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  }
  
  /// コーディネートをローカルストレージから読み込み
  Future<void> _loadOutfits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final outfitsJson = prefs.getStringList(_storageKey);
      
      if (outfitsJson != null) {
        _outfits = outfitsJson
            .map((outfitJson) => Outfit.fromMap(json.decode(outfitJson)))
            .toList();
      } else {
        // サンプルデータを追加
        _addSampleOutfits();
      }
    } catch (e) {
      print('コーディネートの読み込みエラー: $e');
      // エラー時はサンプルデータを使用
      _addSampleOutfits();
    }
  }
  
  /// コーディネートをローカルストレージに保存
  Future<void> _saveOutfits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final outfitsJson = _outfits
          .map((outfit) => json.encode(outfit.toMap()))
          .toList();
      
      await prefs.setStringList(_storageKey, outfitsJson);
    } catch (e) {
      print('コーディネートの保存エラー: $e');
    }
  }
  
  /// サンプルデータを追加
  void _addSampleOutfits() {
    final closetService = ClosetService();
    final allItems = closetService.getAllItems();
    
    // サンプルアイテムが存在する場合のみサンプルコーディネートを作成
    if (allItems.isNotEmpty) {
      final topsItems = allItems.where((item) => item.category == 'トップス').toList();
      final bottomsItems = allItems.where((item) => item.category == 'ボトムス').toList();
      final outerItems = allItems.where((item) => item.category == 'アウター').toList();
      final shoesItems = allItems.where((item) => item.category == 'シューズ').toList();
      
      if (topsItems.isNotEmpty && bottomsItems.isNotEmpty) {
        // カジュアルコーディネート
        final casualOutfit = Outfit(
          id: 1,
          name: 'カジュアルコーディネート',
          itemIds: [
            topsItems.first.id,
            bottomsItems.first.id,
            if (shoesItems.isNotEmpty) shoesItems.first.id,
          ],
          season: '春',
          occasion: 'カジュアル',
          notes: '休日のお出かけ用',
        );
        
        _outfits.add(casualOutfit);
        
        // アウターがある場合は秋冬コーディネートも追加
        if (outerItems.isNotEmpty) {
          final winterOutfit = Outfit(
            id: 2,
            name: '秋冬コーディネート',
            itemIds: [
              topsItems.first.id,
              bottomsItems.first.id,
              outerItems.first.id,
              if (shoesItems.isNotEmpty) shoesItems.first.id,
            ],
            season: '冬',
            occasion: 'カジュアル',
            notes: '防寒対策バッチリ',
          );
          
          _outfits.add(winterOutfit);
        }
      }
    }
  }
  
  /// おすすめコーディネートを生成
  List<Outfit> generateRecommendedOutfits({String? season, String? occasion}) {
    final closetService = ClosetService();
    final allItems = closetService.getAllItems();
    
    // 十分なアイテムがない場合は空のリストを返す
    if (allItems.isEmpty) return [];
    
    List<Outfit> recommendedOutfits = [];
    
    // 季節に応じたアイテムをフィルタリング
    final topsItems = allItems.where((item) => item.category == 'トップス').toList();
    final bottomsItems = allItems.where((item) => item.category == 'ボトムス').toList();
    final outerItems = allItems.where((item) => item.category == 'アウター').toList();
    final shoesItems = allItems.where((item) => item.category == 'シューズ').toList();
    final accessoryItems = allItems.where((item) => item.category == 'アクセサリー').toList();
    
    // トップスとボトムスがある場合のみコーディネートを生成
    if (topsItems.isNotEmpty && bottomsItems.isNotEmpty) {
      // カジュアルコーディネート
      final casualOutfit = Outfit(
        id: generateNewId(),
        name: 'おすすめカジュアル',
        itemIds: [
          topsItems.first.id,
          bottomsItems.first.id,
          if (shoesItems.isNotEmpty) shoesItems.first.id,
          if (accessoryItems.isNotEmpty) accessoryItems.first.id,
        ],
        season: season ?? '春',
        occasion: occasion ?? 'カジュアル',
        notes: '自動生成されたおすすめコーディネート',
      );
      
      recommendedOutfits.add(casualOutfit);
      
      // 秋冬の場合はアウターを追加
      if ((season == '秋' || season == '冬') && outerItems.isNotEmpty) {
        final winterOutfit = Outfit(
          id: generateNewId() + 1,
          name: 'おすすめ秋冬コーデ',
          itemIds: [
            topsItems.first.id,
            bottomsItems.first.id,
            outerItems.first.id,
            if (shoesItems.isNotEmpty) shoesItems.first.id,
          ],
          season: season,
          occasion: occasion ?? 'カジュアル',
          notes: '自動生成されたおすすめコーディネート',
        );
        
        recommendedOutfits.add(winterOutfit);
      }
    }
    
    return recommendedOutfits;
  }
}
