import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../services/closet_service_supabase.dart';
import '../services/outfit_service_supabase.dart';
import '../services/image_service.dart';
import '../services/sample_data_service.dart';
import '../theme/app_theme.dart';
import 'add_item_screen.dart';
import 'create_outfit_screen.dart';
import 'item_detail_screen.dart';
import 'item_list_screen.dart';
import 'outfit_detail_screen.dart';
import 'outfit_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ClosetServiceSupabase _closetService = ClosetServiceSupabase();
  final OutfitServiceSupabase _outfitService = OutfitServiceSupabase();
  final ImageService _imageService = ImageService();
  final SampleDataService _sampleDataService = SampleDataService();
  
  List<ClothingItem> _recentItems = [];
  List<ClothingItem> _mostWornItems = [];
  List<Outfit> _recentOutfits = [];
  
  int _totalItems = 0;
  int _totalOutfits = 0;
  Map<String, int> _categoryCount = {};
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    const bool isTest = bool.fromEnvironment('FLUTTER_TEST');
    if (!isTest) {
      _loadData();
    }
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _closetService.loadItems();
      final allItems = await _closetService.getAllItems();
      final allOutfits = await _outfitService.getAllOutfits();
    
    // 最近追加したアイテム（最大5つ）
    final recentItems = List<ClothingItem>.from(allItems)
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    
    // 最も着用回数の多いアイテム（最大5つ）
    final mostWornItems = List<ClothingItem>.from(allItems)
      ..sort((a, b) => b.wearCount.compareTo(a.wearCount));
    
    // 最近作成したコーディネート（最大5つ）
    final recentOutfits = List<Outfit>.from(allOutfits)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // カテゴリごとのアイテム数
    final categoryCount = <String, int>{};
    for (final item in allItems) {
      categoryCount[item.category] = (categoryCount[item.category] ?? 0) + 1;
    }
    
    setState(() {
      _recentItems = recentItems.take(5).toList();
      _mostWornItems = mostWornItems.where((item) => item.wearCount > 0).take(5).toList();
      _recentOutfits = recentOutfits.take(5).toList();
      _totalItems = allItems.length;
      _totalOutfits = allOutfits.length;
      _categoryCount = categoryCount;
      _isLoading = false;
    });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('エラー'),
            content: Text('データの読み込みに失敗しました: $e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('My Style Closet'),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: _loadData,
            ),
            // クイックアクション
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('クイックアクション', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 72,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(icon: CupertinoIcons.add, label: 'アイテム追加', color: AppTheme.primaryColor, onTap: () => _navigateToAddItem(context)),
                          _buildActionButton(icon: CupertinoIcons.square_on_square, label: 'コーデ作成', color: AppTheme.primaryColor, onTap: () => _navigateToCreateOutfit(context)),
                          _buildActionButton(icon: CupertinoIcons.camera, label: '写真から追加', color: AppTheme.primaryColor, onTap: () => _navigateToAddItemWithCamera(context)),
                          _buildActionButton(icon: CupertinoIcons.chart_bar, label: '統計', color: AppTheme.primaryColor, onTap: () => _showStatistics(context)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_recentItems.isNotEmpty) _buildHorizontalSection<ClothingItem>('最近追加したアイテム', _recentItems, _buildItemCard, () => _navigateToItemList(context)),
            if (_recentOutfits.isNotEmpty) _buildHorizontalSection<Outfit>('最近作成したコーデ', _recentOutfits, _buildOutfitCard, () => _navigateToOutfitList(context)),
            // 下部に余白を追加してオーバーフローを防止
            SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
  
  void _showSampleDataDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('サンプルデータ'),
        content: const Text(
          'サンプルデータを追加または削除します。\n\n'
          '追加: 15個のアイテムと5つのコーディネートのサンプルデータを追加します。\n\n'
          '削除: 現在のすべてのデータを削除します。この操作は元に戻せません。',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllData();
            },
            isDestructiveAction: true,
            child: const Text('すべて削除'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
              _addSampleData();
            },
            isDefaultAction: true,
            child: const Text('サンプル追加'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addSampleData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _sampleDataService.generateSampleData();
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text('サンプルデータ追加'),
            content: Text('サンプルデータを追加しました'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: ( ) => Navigator.of(ctx).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('エラー'),
            content: Text('サンプルデータの追加に失敗しました: $e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadData(); // データを再読み込み
        });
      }
    }
  }
  
  Future<void> _clearAllData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _sampleDataService.clearAllData();
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text('データ削除完了'),
            content: Text('すべてのデータを削除しました'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('エラー'),
            content: Text('データの削除に失敗しました: $e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadData(); // データを再読み込み
        });
      }
    }
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    VoidCallback? onSeeAll,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (onSeeAll != null)
          CupertinoButton(
            onPressed: onSeeAll,
            child: const Text('すべて見る'),
          ),
      ],
    );
  }
  
  Widget _buildItemCard(ClothingItem item) {
    final categoryColor = AppTheme.getCategoryColor(item.category);
    
    return GestureDetector(
      onTap: () => _navigateToItemDetail(context, item),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像
            PhysicalModel(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              shadowColor: Colors.black26,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: item.imageUrl != null
                      ? (item.imageUrl!.startsWith('http')
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => Container(color: categoryColor.withOpacity(0.1)),
                            )
                          : FutureBuilder<dynamic>(
                              future: _imageService.getImageData(item.imageUrl!),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Container(
                                    color: categoryColor.withOpacity(0.1),
                                    child: const Center(child: CupertinoActivityIndicator()),
                                  );
                                }
                                if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                  return Container(
                                    color: categoryColor.withOpacity(0.1),
                                    child: Icon(
                                      AppTheme.getCategoryIcon(item.category),
                                      size: 50,
                                      color: categoryColor.withOpacity(0.5),
                                    ),
                                  );
                                }
                                if (kIsWeb) {
                                  return Image.network(
                                    snapshot.data.toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) => Container(color: categoryColor.withOpacity(0.1)),
                                  );
                                } else {
                                  return Image.file(
                                    snapshot.data as File,
                                    fit: BoxFit.cover,
                                  );
                                }
                              },
                            ))
                      : Container(
                          color: categoryColor.withOpacity(0.1),
                          child: Icon(
                            AppTheme.getCategoryIcon(item.category),
                            size: 50,
                            color: categoryColor.withOpacity(0.5),
                          ),
                        ),
                ),
              ),
            ),
            
            // ブランド名のみ表示
            if (item.brand != null && item.brand!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  item.brand!,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOutfitCard(Outfit outfit) {
    final itemsFuture = _closetService.getItemsByIds(outfit.itemIds);

    return GestureDetector(
      onTap: () => _navigateToOutfitDetail(context, outfit),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像
            PhysicalModel(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              shadowColor: Colors.black26,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  child: FutureBuilder<List<ClothingItem>>(
                    future: itemsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CupertinoActivityIndicator());
                      }
                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return const Center(
                          child: Icon(
                            CupertinoIcons.bag,
                            size: 50,
                            color: AppTheme.primaryColor,
                          ),
                        );
                      }
                      return _buildOutfitPreview(items);
                    },
                  ),
                ),
              ),
            ),
            // 情報
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${outfit.itemIds.length}アイテム',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (outfit.wearCount > 0)
                        Text(
                          '${outfit.wearCount}回着用',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOutfitPreview(List<ClothingItem> items) {
    // 最大4つのアイテムを表示
    final displayItems = items.take(4).toList();
    final gridSize = displayItems.length <= 2 ? 1 : 2;
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
        childAspectRatio: 1,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        final categoryColor = AppTheme.getCategoryColor(item.category);
        
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: item.imageUrl != null
              ? (item.imageUrl!.startsWith('http')
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(color: categoryColor.withOpacity(0.1)),
                    )
                  : FutureBuilder<dynamic>(
                      future: _imageService.getImageData(item.imageUrl!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            color: categoryColor.withOpacity(0.1),
                            child: const Center(child: CupertinoActivityIndicator()),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                          return Container(
                            color: categoryColor.withOpacity(0.1),
                            child: Icon(
                              AppTheme.getCategoryIcon(item.category),
                              size: 30,
                              color: categoryColor.withOpacity(0.5),
                            ),
                          );
                        }
                        if (kIsWeb) {
                          return Image.network(
                            snapshot.data.toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(color: categoryColor.withOpacity(0.1)),
                          );
                        } else {
                          return Image.file(
                            snapshot.data as File,
                            fit: BoxFit.cover,
                          );
                        }
                      },
                    ))
              : Container(
                  color: categoryColor.withOpacity(0.1),
                  child: Icon(
                    AppTheme.getCategoryIcon(item.category),
                    size: 30,
                    color: categoryColor.withOpacity(0.5),
                  ),
                ),
        );
      },
    );
  }
  
  Widget _buildCategoryDistribution() {
    if (_categoryCount.isEmpty) {
      return const Center(
        child: Text('データがありません'),
      );
    }
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _categoryCount.length,
      itemBuilder: (context, index) {
        final category = _categoryCount.keys.elementAt(index);
        final count = _categoryCount[category]!;
        final percentage = count / _totalItems * 100;
        final categoryColor = AppTheme.getCategoryColor(category);
        
        return Container(
          width: 120,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AppTheme.getCategoryIcon(category),
                color: categoryColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                category,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count個 (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
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
      await _loadData();
    }
  }
  
  void _navigateToAddItemWithCamera(BuildContext context) async {
    // カメラ起動して画像取得
    final imagePath = await _imageService.takePicture();
    if (imagePath == null) return;
    final result = await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => AddItemScreen(initialImagePath: imagePath),
      ),
    );
    if (result == true) {
      await _loadData();
    }
  }
  
  void _navigateToCreateOutfit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const CreateOutfitScreen(),
      ),
    );
    
    if (result == true) {
      await _loadData();
    }
  }
  
  void _navigateToItemDetail(BuildContext context, ClothingItem item) async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ItemDetailScreen(item: item),
      ),
    );
    
    await _loadData();
  }
  
  void _navigateToOutfitDetail(BuildContext context, Outfit outfit) async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => OutfitDetailScreen(outfit: outfit),
      ),
    );
    
    await _loadData();
  }
  
  void _navigateToItemList(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const ItemListScreen()),
    );
  }
  
  void _navigateToOutfitList(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const OutfitListScreen()),
    );
  }
  
  void _showStatistics(BuildContext context) {
    // 統計情報を表示
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('クローゼット統計'),
        message: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('アイテム数: $_totalItems'),
            Text('コーデ数: $_totalOutfits'),
            ..._categoryCount.entries.map((e) => Text('${e.key}: ${e.value}')),
          ],
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllData();
            },
            isDestructiveAction: true,
            child: const Text('すべて削除'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _addSampleData();
            },
            child: const Text('サンプル追加'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (color != null)
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHorizontalSection<T>(String title, List<T> items, Widget Function(T) itemBuilder, VoidCallback onSeeAll) {
    final bool isItemSection = items.isNotEmpty && items.first is ClothingItem;
    final double listHeight = isItemSection ? 180.0 : 220.0;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: title,
              icon: CupertinoIcons.square_on_square,
              onSeeAll: onSeeAll,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: listHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return itemBuilder(items[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
