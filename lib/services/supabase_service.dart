import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/catalog_item.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  factory SupabaseService() {
    return _instance;
  }
  
  SupabaseService._internal();
  
  // Supabaseの接続情報
  static const String supabaseUrl = 'https://tazuvwaruvuyamnhqcah.supabase.co';
  static const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhenV2d2FydXZ1eWFtbmhxY2FoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ1MzM0NTcsImV4cCI6MjA2MDEwOTQ1N30.jlDsR7UX2nvuI8u6Klv5VYguRNSCB2mDnvLqR7h7sLk';
  
  SupabaseClient get client => Supabase.instance.client;
  
  // 衣類アイテム関連のメソッド
  
  // 全ての衣類アイテムを取得
  Future<List<Map<String, dynamic>>> getAllClothingItems() async {
    final response = await client
        .from('clothing_items')
        .select()
        .order('date_added', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  // IDで衣類アイテムを取得
  Future<Map<String, dynamic>?> getClothingItemById(String id) async {
    final response = await client
        .from('clothing_items')
        .select()
        .eq('id', id)
        .single();
    
    return response;
  }
  
  // 衣類アイテムを追加
  Future<Map<String, dynamic>> addClothingItem(Map<String, dynamic> item) async {
    final response = await client
        .from('clothing_items')
        .insert(item)
        .select()
        .single();
    
    return response;
  }
  
  // 衣類アイテムを更新
  Future<Map<String, dynamic>> updateClothingItem(String id, Map<String, dynamic> item) async {
    final response = await client
        .from('clothing_items')
        .update(item)
        .eq('id', id)
        .select()
        .single();
    
    return response;
  }
  
  // 衣類アイテムを削除
  Future<void> deleteClothingItem(String id) async {
    await client
        .from('clothing_items')
        .delete()
        .eq('id', id);
  }
  
  // 着用回数を増やす
  Future<void> incrementWearCount(String id) async {
    await client.rpc('increment_wear_count', params: {'item_id': id});
  }
  
  // コーディネート関連のメソッド
  
  // 全てのコーディネートを取得
  Future<List<Map<String, dynamic>>> getAllOutfits() async {
    final response = await client
        .from('outfits')
        .select('*, outfit_items(clothing_item_id)')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  // IDでコーディネートを取得
  Future<Map<String, dynamic>?> getOutfitById(String id) async {
    final response = await client
        .from('outfits')
        .select('*, outfit_items(clothing_item_id)')
        .eq('id', id)
        .single();
    
    return response;
  }
  
  // コーディネートを追加 (直接挿入)
  Future<Map<String, dynamic>> addOutfit(Map<String, dynamic> outfit, List<String> itemIds) async {
    // 'notes', 'season', 'occasion' はテーブルに存在しないため除外
    final payload = Map<String, dynamic>.from(outfit)
      ..remove('notes')
      ..remove('season')
      ..remove('occasion')
      ..removeWhere((key, value) => value == null);
    // outfits テーブルにコーディネートを追加
    final insertedOutfit = await client
      .from('outfits')
      .insert(payload)
      .select()
      .single() as Map<String, dynamic>;
    final outfitId = insertedOutfit['id'] as String;
    // outfit_items テーブルに関連アイテムを追加
    final itemsData = itemIds.map((id) => {
      'outfit_id': outfitId,
      'clothing_item_id': id,
    }).toList();
    final insertedItems = await client
      .from('outfit_items')
      .insert(itemsData)
      .select('clothing_item_id') as List<dynamic>;
    // 作成済みコーディネート情報 + 挿入済みアイテムリストを返却
    return {...insertedOutfit, 'items': insertedItems};
  }
  
  // コーディネートを更新
  Future<void> updateOutfit(String id, Map<String, dynamic> outfit, List<String> itemIds) async {
    await client.rpc('update_outfit', params: {
      'outfit_id': id,
      'outfit_data': outfit,
      'item_ids': itemIds
    });
  }
  
  // コーディネートを削除
  Future<void> deleteOutfit(String id) async {
    await client
        .from('outfits')
        .delete()
        .eq('id', id);
  }
  
  // 着用回数を増やす
  Future<void> incrementOutfitWearCount(String id) async {
    await client.rpc('increment_outfit_wear_count', params: {'outfit_id': id});
  }
  
  // 天気関連のメソッド
  
  // 現在の天気データを取得
  Future<Map<String, dynamic>?> getCurrentWeather(String location) async {
    final response = await client
        .from('weather_data')
        .select()
        .eq('location', location)
        .eq('forecast', false)
        .order('timestamp', ascending: false)
        .limit(1)
        .maybeSingle();
    
    return response;
  }
  
  // 天気データを追加
  Future<Map<String, dynamic>> addWeatherData(Map<String, dynamic> weatherData) async {
    final response = await client
        .from('weather_data')
        .insert(weatherData)
        .select()
        .single();
    
    return response;
  }
  
  // 天気に基づくコーディネート提案を取得
  Future<List<Map<String, dynamic>>> getWeatherOutfitSuggestions(
      String condition, double temperature) async {
    final response = await client
        .from('weather_outfit_suggestions')
        .select('*, outfits(*, outfit_items(clothing_item_id))')
        .eq('weather_condition', condition)
        .lte('max_temperature', temperature)
        .gte('min_temperature', temperature);
    
    return response;
  }
  
  // カタログアイテム検索
  Future<List<CatalogItem>> searchCatalogItems(String pattern) async {
    final data = await client
      .from('catalog_items')
      .select()
      .ilike('name', '%$pattern%')
      .limit(10)
      .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(data)
      .map((e) => CatalogItem.fromJson(e))
      .toList();
  }
}
