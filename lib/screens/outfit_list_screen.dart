import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/outfit.dart';
import '../models/clothing_item.dart';
import '../services/outfit_service_supabase.dart';
import '../services/closet_service_supabase.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'create_outfit_screen.dart';
import 'outfit_detail_screen.dart';
import 'package:flutter/cupertino.dart';

class OutfitListScreen extends StatefulWidget {
  const OutfitListScreen({super.key});

  @override
  State<OutfitListScreen> createState() => _OutfitListScreenState();
}

class _OutfitListScreenState extends State<OutfitListScreen> {
  final OutfitServiceSupabase _outfitService = OutfitServiceSupabase();
  final ClosetServiceSupabase _closetService = ClosetServiceSupabase();
  
  bool _isLoading = false;
  
  List<Outfit> _outfits = [];
  List<Outfit> _filteredOutfits = [];
  
  String _searchQuery = '';
  String _sortBy = '作成日（新しい順）';
  
  final List<String> _sortOptions = [
    '作成日（新しい順）',
    '作成日（古い順）',
    '着用回数（多い順）',
    '着用回数（少ない順）',
    '名前（昇順）',
    '名前（降順）',
  ];
  
  @override
  void initState() {
    super.initState();
    _loadOutfits();
  }
  
  Future<void> _loadOutfits() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final outfits = await _outfitService.getAllOutfits();
      
      if (mounted) {
        setState(() {
          _outfits = outfits;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading outfits: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('コーディネートの読み込みに失敗しました: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _applyFilters() {
    List<Outfit> result = List.from(_outfits);
    
    // 検索クエリ
    if (_searchQuery.isNotEmpty) {
      result = result.where((outfit) {
        return outfit.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // ソート
    switch (_sortBy) {
      case '作成日（新しい順）':
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case '作成日（古い順）':
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case '着用回数（多い順）':
        result.sort((a, b) => b.wearCount.compareTo(a.wearCount));
        break;
      case '着用回数（少ない順）':
        result.sort((a, b) => a.wearCount.compareTo(b.wearCount));
        break;
      case '名前（昇順）':
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case '名前（降順）':
        result.sort((a, b) => b.name.compareTo(a.name));
        break;
    }
    
    setState(() {
      _filteredOutfits = result;
    });
  }

  Future<void> _showSortOptions(BuildContext context) async {
    final selected = await showCupertinoModalPopup<String>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('並べ替え'),
        actions: _sortOptions.map((opt) => CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, opt),
          child: Text(opt),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ),
    );
    if (selected != null && selected != _sortBy) {
      setState(() {
        _sortBy = selected;
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('コーディネート'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => _navigateToCreateOutfit(context),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CupertinoSearchTextField(
                placeholder: 'コーディネートを検索...',
                onChanged: (v) => setState(() { _searchQuery = v; _applyFilters(); }),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('並べ替え', style: TextStyle(fontSize: 16)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(_sortBy, style: const TextStyle(fontSize: 16)),
                    onPressed: () => _showSortOptions(context),
                  ),
                ],
              ),
            ),
            
            // コーディネートリスト
            Expanded(
              child: _filteredOutfits.isEmpty
                  ? EmptyState(
                      icon: Icons.style,
                      title: 'コーディネートがありません',
                      message: _searchQuery.isNotEmpty
                          ? '検索条件に一致するコーディネートがありません'
                          : 'コーディネートを作成して服の組み合わせを保存しましょう',
                      actionLabel: 'コーディネートを作成',
                      onAction: () => _navigateToCreateOutfit(context),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredOutfits.length,
                      itemBuilder: (context, index) {
                        final outfit = _filteredOutfits[index];
                        return _buildOutfitCard(outfit);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOutfitCard(Outfit outfit) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _markAsWorn(outfit),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.check,
            label: '着用',
          ),
          SlidableAction(
            onPressed: (context) => _navigateToEditOutfit(context, outfit),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '編集',
          ),
          SlidableAction(
            onPressed: (context) => _confirmDelete(outfit),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '削除',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _navigateToOutfitDetail(context, outfit),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 名前と着用回数
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        outfit.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (outfit.wearCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${outfit.wearCount}回着用',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // 作成日と最終着用日
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '作成: ${_formatDate(outfit.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (outfit.lastWorn != null) ...[
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '最終着用: ${_formatDate(outfit.lastWorn!)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // アイテムプレビュー
                Text(
                  'アイテム (${outfit.itemIds.length}個)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // アイテムチップ
                FutureBuilder<List<ClothingItem>>(
                  future: _outfitService.getItemsInOutfit(outfit),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CupertinoActivityIndicator());
                    }
                    
                    final items = snapshot.data ?? [];
                    
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: items.map((item) {
                    final categoryColor = AppTheme.getCategoryColor(item.category);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppTheme.getCategoryIcon(item.category),
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.name,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
  
  void _navigateToCreateOutfit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const CreateOutfitScreen(),
      ),
    );
    
    if (result == true) {
      _loadOutfits();
    }
  }
  
  void _navigateToEditOutfit(BuildContext context, Outfit outfit) async {
    final result = await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => CreateOutfitScreen(outfitToEdit: outfit),
      ),
    );
    
    if (result == true) {
      _loadOutfits();
    }
  }
  
  void _navigateToOutfitDetail(BuildContext context, Outfit outfit) async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => OutfitDetailScreen(outfit: outfit),
      ),
    );
    
    _loadOutfits();
  }
  
  void _confirmDelete(Outfit outfit) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('コーディネートの削除'),
        content: Text('${outfit.name}を削除してもよろしいですか？'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteOutfit(outfit);
            },
            isDestructiveAction: true,
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
  
  void _deleteOutfit(Outfit outfit) async {
    try {
      await _outfitService.removeOutfit(outfit.id);
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('削除完了'),
            content: Text('${outfit.name}を削除しました'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        _loadOutfits();
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('削除失敗'),
            content: Text('コーディネートの削除に失敗しました: $e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
  
  void _markAsWorn(Outfit outfit) async {
    try {
      final updatedOutfit = outfit.markAsWorn();
      await _outfitService.updateOutfit(updatedOutfit);
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('着用完了'),
            content: Text('${outfit.name}を着用しました'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        _loadOutfits();
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('着用失敗'),
            content: Text('着用記録の更新に失敗しました: $e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
