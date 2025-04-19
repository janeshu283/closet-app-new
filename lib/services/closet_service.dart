import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clothing_item.dart';

class ClosetService {
  static final ClosetService _instance = ClosetService._internal();
  
  factory ClosetService() {
    return _instance;
  }
  
  ClosetService._internal();
  
  List<ClothingItem> _items = [];
  bool _initialized = false;
  
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    
    await loadItems();
    _initialized = true;
  }
  
  Future<void> loadItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getStringList('clothing_items') ?? [];
      
      _items = itemsJson
          .map((itemJson) => ClothingItem.fromJson(jsonDecode(itemJson)))
          .toList();
    } catch (e) {
      print('Error loading items: $e');
      _items = [];
    }
  }
  
  Future<void> saveItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = _items
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      
      await prefs.setStringList('clothing_items', itemsJson);
    } catch (e) {
      print('Error saving items: $e');
    }
  }
  
  List<ClothingItem> getAllItems() {
    return [..._items];
  }
  
  Future<void> addItem(ClothingItem item) async {
    await _ensureInitialized();
    
    _items.add(item);
    await saveItems();
  }
  
  Future<void> updateItem(ClothingItem updatedItem) async {
    await _ensureInitialized();
    
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      await saveItems();
    }
  }
  
  Future<void> removeItem(int id) async {
    await _ensureInitialized();
    
    _items.removeWhere((item) => item.id == id);
    await saveItems();
  }
  
  List<ClothingItem> getItemsByCategory(String category) {
    return _items.where((item) => item.category == category).toList();
  }
  
  List<ClothingItem> getItemsByColor(String color) {
    return _items.where((item) => item.color == color).toList();
  }
  
  // IDからアイテムを取得するメソッド
  ClothingItem? getItemById(int id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      return _items[index];
    }
    return null;
  }
  
  // 複数のIDからアイテムのリストを取得するメソッド
  List<ClothingItem> getItemsByIds(List<int> ids) {
    return _items.where((item) => ids.contains(item.id)).toList();
  }
  
  // アイテムを着用済みとしてマークするメソッド
  Future<void> markItemAsWorn(int id) async {
    await _ensureInitialized();
    
    final item = getItemById(id);
    if (item != null) {
      final updatedItem = item.markAsWorn();
      await updateItem(updatedItem);
    }
  }
  
  // 着用回数でソートされたアイテムを取得
  List<ClothingItem> getMostWornItems({int limit = 5}) {
    final sortedItems = [..._items]..sort((a, b) => b.wearCount.compareTo(a.wearCount));
    return sortedItems.take(limit).toList();
  }
  
  // 最近追加されたアイテムを取得
  List<ClothingItem> getRecentItems({int limit = 5}) {
    final sortedItems = [..._items]..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return sortedItems.take(limit).toList();
  }
}
