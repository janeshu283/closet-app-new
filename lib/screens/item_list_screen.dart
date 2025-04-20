import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clothing_item.dart';
import '../services/closet_service_supabase.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final ClosetServiceSupabase _closetService = ClosetServiceSupabase();
  final ImageService _imageService = ImageService();
  late final StreamSubscription<List<Map<String, dynamic>>> _itemsSubscription;
  
  List<ClothingItem> _items = [];
  
  String _searchQuery = '';
  
  final List<String> _categories = ['Tシャツ', 'シャツ', 'パーカー', 'アウター', 'パンツ', 'シューズ', 'アクセサリー'];
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadItems();
    _itemsSubscription = Supabase.instance.client
      .from('clothing_items')
      .stream(primaryKey: ['id'])
      .listen((_) => _loadItems());
  }
  
  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Reload items from Supabase to include newly added items
      await _closetService.loadItems();
      final items = await _closetService.getAllItems();
      
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('エラー'),
            content: Text('アイテムの読み込みに失敗しました: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  List<ClothingItem> _getItemsByCategory(String category) {
    return _items.where((item) {
      final nameMatch = _searchQuery.isEmpty || item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final brandMatch = _searchQuery.isEmpty || (item.brand?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return item.category == category && (nameMatch || brandMatch);
    }).toList();
  }
  
  Widget _buildCategorySection(String category) {
    final items = _getItemsByCategory(category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            category,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => _navigateToItemDetail(context, item),
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PhysicalModel(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 4,
                        shadowColor: Colors.black26,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: item.imageUrl != null
                                ? (item.imageUrl!.startsWith('http')
                                    ? Image.network(
                                        item.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(color: Colors.grey[200]);
                                        },
                                      )
                                    : FutureBuilder(
                                        future: _imageService.getImageData(item.imageUrl!),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return Container(color: Colors.grey[200]);
                                          }
                                          if (snapshot.hasError || snapshot.data == null) {
                                            return Container(color: Colors.grey[200]);
                                          }
                                          if (kIsWeb) {
                                            return Image.network(snapshot.data.toString(), fit: BoxFit.cover);
                                          } else {
                                            return Image.file(snapshot.data as File, fit: BoxFit.cover);
                                          }
                                        },
                                      ))
                                : Container(color: Colors.grey[200]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (item.brand != null && item.brand!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            item.brand!,
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('クローゼット'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => _navigateToAddItem(context),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CupertinoSearchTextField(
                placeholder: 'アイテムを検索...',
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: _items.isEmpty
                  ? EmptyState(
                      icon: CupertinoIcons.checkmark_circle,
                      title: 'アイテムがありません',
                      message: _searchQuery.isNotEmpty
                          ? '検索条件に一致するアイテムがありません'
                          : 'アイテムを追加してクローゼットを充実させましょう',
                      actionLabel: 'アイテムを追加',
                      onAction: () => _navigateToAddItem(context),
                    )
                  : ListView(
                      children: [
                        for (final category in _categories)
                          _buildCategorySection(category),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToAddItem(BuildContext context) async {
    final result = await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const AddItemScreen(),
      ),
    );
    
    if (result == true) {
      _loadItems();
    }
  }
  
  void _navigateToItemDetail(BuildContext context, ClothingItem item) async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ItemDetailScreen(item: item),
      ),
    );
    
    _loadItems();
  }

  @override
  void dispose() {
    _itemsSubscription.cancel();
    super.dispose();
  }
}
