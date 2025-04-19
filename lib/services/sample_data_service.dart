import 'dart:math';
import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../services/closet_service_supabase.dart';
import '../services/outfit_service_supabase.dart';

class SampleDataService {
  static final SampleDataService _instance = SampleDataService._internal();
  
  factory SampleDataService() {
    return _instance;
  }
  
  SampleDataService._internal();
  
  final ClosetServiceSupabase _closetService = ClosetServiceSupabase();
  final OutfitServiceSupabase _outfitService = OutfitServiceSupabase();
  
  // サンプルデータの生成と保存
  Future<void> generateSampleData() async {
    // サンプルアイテムの生成
    final sampleItems = _generateSampleItems();
    
    // サンプルアイテムの保存
    for (final item in sampleItems) {
      await _closetService.addItem(item);
    }
    
    // サンプルコーディネートの生成と保存
    final sampleOutfits = _generateSampleOutfits(sampleItems);
    for (final outfit in sampleOutfits) {
      await _outfitService.addOutfit(outfit);
    }
  }
  
  // サンプルアイテムの生成
  List<ClothingItem> _generateSampleItems() {
    final items = <ClothingItem>[];
    final random = Random();
    
    // トップス
    items.add(ClothingItem(
      name: '白Tシャツ',
      category: 'トップス',
      color: '白',
      brand: 'ユニクロ',
      size: 'M',
      material: 'コットン',
      dateAdded: DateTime.now().subtract(const Duration(days: 30)),
      wearCount: random.nextInt(10),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    ));
    
    items.add(ClothingItem(
      name: '黒Tシャツ',
      category: 'トップス',
      color: '黒',
      brand: 'ユニクロ',
      size: 'M',
      material: 'コットン',
      dateAdded: DateTime.now().subtract(const Duration(days: 25)),
      wearCount: random.nextInt(10),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    ));
    
    items.add(ClothingItem(
      name: 'ストライプシャツ',
      category: 'トップス',
      color: '白',
      brand: 'ZARA',
      size: 'L',
      material: 'コットン',
      dateAdded: DateTime.now().subtract(const Duration(days: 20)),
      wearCount: random.nextInt(5),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    ));
    
    items.add(ClothingItem(
      name: 'ニットセーター',
      category: 'トップス',
      color: 'ベージュ',
      brand: 'GU',
      size: 'M',
      material: 'ウール',
      dateAdded: DateTime.now().subtract(const Duration(days: 15)),
      wearCount: random.nextInt(5),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    ));
    
    items.add(ClothingItem(
      name: 'パーカー',
      category: 'トップス',
      color: 'グレー',
      brand: 'ナイキ',
      size: 'L',
      material: 'コットン',
      dateAdded: DateTime.now().subtract(const Duration(days: 10)),
      wearCount: random.nextInt(8),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    ));
    
    // ボトムス
    items.add(ClothingItem(
      name: 'ジーンズ',
      category: 'ボトムス',
      color: '青',
      brand: 'リーバイス',
      size: '30',
      material: 'デニム',
      dateAdded: DateTime.now().subtract(const Duration(days: 40)),
      wearCount: random.nextInt(15),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    ));
    
    items.add(ClothingItem(
      name: 'チノパン',
      category: 'ボトムス',
      color: 'ベージュ',
      brand: 'ユニクロ',
      size: 'M',
      material: 'コットン',
      dateAdded: DateTime.now().subtract(const Duration(days: 35)),
      wearCount: random.nextInt(10),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    ));
    
    items.add(ClothingItem(
      name: 'スウェットパンツ',
      category: 'ボトムス',
      color: 'グレー',
      brand: 'アディダス',
      size: 'M',
      material: 'コットン',
      dateAdded: DateTime.now().subtract(const Duration(days: 30)),
      wearCount: random.nextInt(12),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    ));
    
    // アウター
    items.add(ClothingItem(
      name: 'デニムジャケット',
      category: 'アウター',
      color: '青',
      brand: 'リーバイス',
      size: 'M',
      material: 'デニム',
      dateAdded: DateTime.now().subtract(const Duration(days: 60)),
      wearCount: random.nextInt(8),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    ));
    
    items.add(ClothingItem(
      name: 'レザージャケット',
      category: 'アウター',
      color: '黒',
      brand: 'ZARA',
      size: 'M',
      material: 'レザー',
      dateAdded: DateTime.now().subtract(const Duration(days: 55)),
      wearCount: random.nextInt(6),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    ));
    
    items.add(ClothingItem(
      name: 'トレンチコート',
      category: 'アウター',
      color: 'ベージュ',
      brand: 'バーバリー',
      size: 'M',
      material: 'コットン',
      dateAdded: DateTime.now().subtract(const Duration(days: 50)),
      wearCount: random.nextInt(5),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    ));
    
    // シューズ
    items.add(ClothingItem(
      name: 'スニーカー',
      category: 'シューズ',
      color: '白',
      brand: 'ナイキ',
      size: '27.0',
      material: 'キャンバス',
      dateAdded: DateTime.now().subtract(const Duration(days: 45)),
      wearCount: random.nextInt(20),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    ));
    
    items.add(ClothingItem(
      name: 'ブーツ',
      category: 'シューズ',
      color: '黒',
      brand: 'ドクターマーチン',
      size: '27.0',
      material: 'レザー',
      dateAdded: DateTime.now().subtract(const Duration(days: 40)),
      wearCount: random.nextInt(10),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    ));
    
    // アクセサリー
    items.add(ClothingItem(
      name: '腕時計',
      category: 'アクセサリー',
      color: 'シルバー',
      brand: 'セイコー',
      size: 'フリー',
      material: 'ステンレス',
      dateAdded: DateTime.now().subtract(const Duration(days: 35)),
      wearCount: random.nextInt(25),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    ));
    
    items.add(ClothingItem(
      name: 'ネックレス',
      category: 'アクセサリー',
      color: 'シルバー',
      brand: 'ティファニー',
      size: 'フリー',
      material: 'シルバー925',
      dateAdded: DateTime.now().subtract(const Duration(days: 30)),
      wearCount: random.nextInt(15),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    ));
    
    return items;
  }
  
  // サンプルコーディネートの生成
  List<Outfit> _generateSampleOutfits(List<ClothingItem> items) {
    final outfits = <Outfit>[];
    final random = Random();
    final itemIds = items.map((item) => item.id as String).toList();
    
    // カジュアルコーデ
    outfits.add(Outfit(
      name: 'カジュアルデイリーコーデ',
      itemIds: [itemIds[0], itemIds[5], itemIds[11], itemIds[13]], // 白Tシャツ、ジーンズ、スニーカー、腕時計
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      wearCount: random.nextInt(8),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(20))),
      season: '春',
      occasion: 'カジュアル',
    ));
    
    // オフィスカジュアルコーデ
    outfits.add(Outfit(
      name: 'オフィスカジュアルコーデ',
      itemIds: [itemIds[2], itemIds[6], itemIds[12], itemIds[13]], // ストライプシャツ、チノパン、ブーツ、腕時計
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      wearCount: random.nextInt(5),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(15))),
      season: '春',
      occasion: 'オフィス',
    ));
    
    // 秋冬コーデ
    outfits.add(Outfit(
      name: '秋冬の定番コーデ',
      itemIds: [itemIds[3], itemIds[6], itemIds[10], itemIds[12], itemIds[13]], // ニットセーター、チノパン、トレンチコート、ブーツ、腕時計
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      wearCount: random.nextInt(3),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(10))),
      season: '秋',
      occasion: 'カジュアル',
    ));
    
    // リラックスコーデ
    outfits.add(Outfit(
      name: 'リラックスホームウェア',
      itemIds: [itemIds[4], itemIds[7], itemIds[11]], // パーカー、スウェットパンツ、スニーカー
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      wearCount: random.nextInt(10),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(5))),
      season: '春',
      occasion: 'カジュアル',
    ));
    
    // ロックスタイル
    outfits.add(Outfit(
      name: 'ロックスタイル',
      itemIds: [itemIds[1], itemIds[5], itemIds[9], itemIds[12], itemIds[14]], // 黒Tシャツ、ジーンズ、レザージャケット、ブーツ、ネックレス
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      wearCount: random.nextInt(2),
      lastWorn: DateTime.now().subtract(Duration(days: random.nextInt(3))),
      season: '秋',
      occasion: 'パーティー',
    ));
    
    return outfits;
  }
  
  // データのクリア
  Future<void> clearAllData() async {
    try {
      // 全アイテムを取得
      final items = await _closetService.getAllItems();
      
      // 各アイテムを削除
      for (final item in items) {
        await _closetService.removeItem(item.id);
      }
      
      // 全コーディネートを取得
      final outfits = await _outfitService.getAllOutfits();
      
      // 各コーディネートを削除
      for (final outfit in outfits) {
        await _outfitService.removeOutfit(outfit.id);
      }
    } catch (e) {
      print('Error clearing data: $e');
      throw Exception('データの削除に失敗しました');
    }
  }
}
