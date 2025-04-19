import 'clothing_item.dart';
import 'package:uuid/uuid.dart';

/// コーディネートを表すモデルクラス
class Outfit {
  final String id;
  final String name;
  final List<String> itemIds; // 含まれる衣類アイテムのID一覧
  final DateTime createdAt;
  final DateTime? lastWorn;
  final int wearCount;
  final String? season; // 季節（春、夏、秋、冬）
  final String? occasion; // 場面（カジュアル、フォーマル、スポーツなど）
  final String? notes; // メモ
  final String? description; // 説明文

  Outfit({
    String? id,
    required this.name,
    required this.itemIds,
    DateTime? createdAt,
    this.lastWorn,
    this.wearCount = 0,
    this.season,
    this.occasion,
    this.notes,
    this.description,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  /// コーディネートが着用されたことを記録
  Outfit markAsWorn() {
    return Outfit(
      id: id,
      name: name,
      itemIds: itemIds,
      createdAt: createdAt,
      lastWorn: DateTime.now(),
      wearCount: wearCount + 1,
      season: season,
      occasion: occasion,
      notes: notes,
      description: description,
    );
  }

  /// マップからOutfitを作成（SharedPreferences用）
  factory Outfit.fromMap(Map<String, dynamic> map) {
    return Outfit(
      id: map['id'],
      name: map['name'],
      itemIds: List<String>.from(map['itemIds']),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : null,
      lastWorn: map['lastWorn'] != null 
          ? DateTime.parse(map['lastWorn']) 
          : null,
      wearCount: map['wearCount'] ?? 0,
      season: map['season'],
      occasion: map['occasion'],
      notes: map['notes'],
      description: map['description'],
    );
  }
  
  /// Supabaseから取得したデータからOutfitを作成
  factory Outfit.fromSupabase(Map<String, dynamic> map, List<dynamic> outfitItems) {
    return Outfit(
      id: map['id'],
      name: map['name'],
      itemIds: outfitItems.map<String>((item) => item['clothing_item_id'] as String).toList(),
      createdAt: DateTime.parse(map['created_at']),
      lastWorn: map['last_worn'] != null 
          ? DateTime.parse(map['last_worn']) 
          : null,
      wearCount: map['wear_count'] ?? 0,
      description: map['description'],
      season: map['season'],
      occasion: map['occasion'],
      notes: map['notes'],
    );
  }

  /// Outfitをマップに変換（SharedPreferences用）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'itemIds': itemIds,
      'createdAt': createdAt.toIso8601String(),
      'lastWorn': lastWorn?.toIso8601String(),
      'wearCount': wearCount,
      'season': season,
      'occasion': occasion,
      'notes': notes,
      'description': description,
    };
  }
  
  /// Supabase用にデータを変換
  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'description': description,
      'wear_count': wearCount,
      'last_worn': lastWorn?.toIso8601String(),
      'season': season,
      'occasion': occasion,
      'notes': notes,
    };
  }
}
