import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ClothingItem {
  final String id;
  final String name;
  final String category;
  final String color;
  final String? imageUrl;
  final DateTime dateAdded;
  final String? brand;
  final String? size;
  final String? material;
  final int wearCount;
  final DateTime? lastWorn;

  ClothingItem({
    String? id,
    required this.name,
    required this.category,
    required this.color,
    this.imageUrl,
    DateTime? dateAdded,
    this.brand,
    this.size,
    this.material,
    this.wearCount = 0,
    this.lastWorn,
  }) : id = id ?? const Uuid().v4(),
       dateAdded = dateAdded ?? DateTime.now();

  ClothingItem markAsWorn() {
    return ClothingItem(
      id: id,
      name: name,
      category: category,
      color: color,
      imageUrl: imageUrl,
      dateAdded: dateAdded,
      brand: brand,
      size: size,
      material: material,
      wearCount: wearCount + 1,
      lastWorn: DateTime.now(),
    );
  }
  
  // JSON変換メソッドを追加
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'color': color,
      'image_url': imageUrl,
      'date_added': dateAdded.toIso8601String(),
      'brand': brand,
      'size': size,
      'material': material,
      'wear_count': wearCount,
      'last_worn': lastWorn?.toIso8601String(),
    };
  }
  
  // Supabaseから取得したデータを変換するメソッド
  factory ClothingItem.fromSupabase(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      color: json['color'],
      imageUrl: json['image_url'],
      dateAdded: DateTime.parse(json['date_added']),
      brand: json['brand'],
      size: json['size'],
      material: json['material'],
      wearCount: json['wear_count'],
      lastWorn: json['last_worn'] != null ? DateTime.parse(json['last_worn']) : null,
    );
  }
  
  // SharedPreferencesとの互換性のためのメソッド
  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      color: json['color'],
      imageUrl: json['imageUrl'],
      dateAdded: DateTime.parse(json['dateAdded']),
      brand: json['brand'],
      size: json['size'],
      material: json['material'],
      wearCount: json['wearCount'],
      lastWorn: json['lastWorn'] != null ? DateTime.parse(json['lastWorn']) : null,
    );
  }
}
