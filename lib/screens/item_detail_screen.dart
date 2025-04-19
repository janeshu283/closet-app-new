import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/clothing_item.dart';
import '../services/closet_service_supabase.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';
import 'add_item_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final ClothingItem item;

  const ItemDetailScreen({
    super.key,
    required this.item,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late ClothingItem _item;
  final ClosetServiceSupabase _closetService = ClosetServiceSupabase();
  final ImageService _imageService = ImageService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppTheme.getCategoryColor(_item.category);
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // アプリバー
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: categoryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildItemImage(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _editItem,
                tooltip: '編集',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _confirmDelete,
                tooltip: '削除',
              ),
            ],
          ),
          
          // アイテム情報
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // アイテム名と基本情報
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _item.name,
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildCategoryChip(_item.category, categoryColor),
                                const SizedBox(width: 8),
                                _buildColorChip(_item.color),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 着用ボタン
                      _buildWearButton(categoryColor),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 詳細情報セクション
                  _buildSectionTitle('詳細情報', Icons.info_outline),
                  const SizedBox(height: 16),
                  
                  _buildDetailCard([
                    if (_item.brand != null && _item.brand!.isNotEmpty)
                      _buildDetailRow('ブランド', _item.brand!),
                    if (_item.size != null && _item.size!.isNotEmpty)
                      _buildDetailRow('サイズ', _item.size!),
                    if (_item.material != null && _item.material!.isNotEmpty)
                      _buildDetailRow('素材', _item.material!),
                    _buildDetailRow('追加日', _formatDate(_item.dateAdded)),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // 着用履歴セクション
                  _buildSectionTitle('着用履歴', Icons.history),
                  const SizedBox(height: 16),
                  
                  _buildDetailCard([
                    _buildDetailRow('着用回数', '${_item.wearCount}回'),
                    if (_item.lastWorn != null)
                      _buildDetailRow('最終着用日', _formatDate(_item.lastWorn!)),
                  ]),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildItemImage() {
    // ネットワークURLなら直接表示
    if (_item.imageUrl!.startsWith('http')) {
      return Image.network(
        _item.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) {
          return Container(
            color: AppTheme.getCategoryColor(_item.category).withOpacity(0.1),
            child: Center(
              child: Icon(
                AppTheme.getCategoryIcon(_item.category),
                size: 100,
                color: AppTheme.getCategoryColor(_item.category).withOpacity(0.5),
              ),
            ),
          );
        },
      );
    }
    // ローカル/カメラ画像の場合はImageServiceを使用
    return FutureBuilder<dynamic>(
      future: _imageService.getImageData(_item.imageUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Container(
            color: AppTheme.getCategoryColor(_item.category).withOpacity(0.1),
            child: Center(
              child: Icon(
                AppTheme.getCategoryIcon(_item.category),
                size: 100,
                color: AppTheme.getCategoryColor(_item.category).withOpacity(0.5),
              ),
            ),
          );
        }
        return Image.file(
          snapshot.data as File,
          fit: BoxFit.cover,
        );
      },
    );
  }
  
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryChip(String category, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppTheme.getCategoryIcon(category),
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            category,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  Widget _buildColorChip(String colorName) {
    final Color color = _getColorFromName(colorName);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            colorName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case '白': return Colors.white;
      case '黒': return Colors.black;
      case '赤': return Colors.red;
      case '青': return Colors.blue;
      case '緑': return Colors.green;
      case '黄': return Colors.yellow;
      case 'ピンク': return Colors.pink;
      case 'パープル': return Colors.purple;
      case 'グレー': return Colors.grey;
      case 'ベージュ': return const Color(0xFFE8D4B9);
      case 'ブラウン': return Colors.brown;
      case 'ネイビー': return const Color(0xFF000080);
      case 'オレンジ': return Colors.orange;
      case 'ターコイズ': return const Color(0xFF40E0D0);
      default: return Colors.grey;
    }
  }
  
  Widget _buildWearButton(Color color) {
    return ElevatedButton.icon(
      onPressed: _markAsWorn,
      icon: const Icon(Icons.check),
      label: const Text('着用'),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
  
  void _editItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemScreen(itemToEdit: _item),
      ),
    );
    
    if (result == true) {
      try {
        // 編集後にアイテムを再取得
        final updatedItem = await _closetService.getItemById(_item.id);
        if (updatedItem != null) {
          setState(() {
            _item = updatedItem;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('アイテムの取得に失敗しました: $e')),
          );
        }
      }
    }
  }
  
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アイテムの削除'),
        content: Text('${_item.name}を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteItem();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
  
  void _deleteItem() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _closetService.removeItem(_item.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_item.name}を削除しました')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アイテムの削除に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _markAsWorn() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final updatedItem = _item.markAsWorn();
      await _closetService.updateItem(updatedItem);
      
      setState(() {
        _item = updatedItem;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_item.name}を着用しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('着用記録の更新に失敗しました: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
