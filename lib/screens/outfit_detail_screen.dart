import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/outfit.dart';
import '../models/clothing_item.dart';
import '../services/outfit_service_supabase.dart';
import '../services/image_service.dart';
import 'item_detail_screen.dart';
import 'create_outfit_screen.dart';

class OutfitDetailScreen extends StatefulWidget {
  final Outfit outfit;

  const OutfitDetailScreen({
    super.key,
    required this.outfit,
  });

  @override
  State<OutfitDetailScreen> createState() => _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends State<OutfitDetailScreen> {
  final OutfitServiceSupabase _outfitService = OutfitServiceSupabase();
  final ImageService _imageService = ImageService();
  late Outfit _outfit;
  List<ClothingItem> _items = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _outfit = widget.outfit;
    _loadItems();
  }
  
  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final items = await _outfitService.getItemsInOutfit(_outfit);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading outfit items: $e');
      setState(() {
        _items = [];
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アイテムの読み込みに失敗しました: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_outfit.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editOutfit,
            tooltip: '編集',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
            tooltip: '削除',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            
            _buildItemsSection(),
            const SizedBox(height: 24),
            
            _buildWearSection(),
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: _markAsWorn,
              icon: const Icon(Icons.check),
              label: const Text('着用済みとしてマーク'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('コーディネート名', _outfit.name),
            if (_outfit.season != null) _buildInfoRow('季節', _outfit.season!),
            if (_outfit.occasion != null) _buildInfoRow('場面', _outfit.occasion!),
            if (_outfit.notes != null && _outfit.notes!.isNotEmpty) _buildInfoRow('メモ', _outfit.notes!),
            _buildInfoRow('作成日', _formatDate(_outfit.createdAt)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('アイテム一覧', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        _items.isEmpty
            ? const Center(child: Text('アイテムがありません'))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: _buildItemImage(item),
                      title: Text(item.name),
                      subtitle: Text('${item.category} • ${item.color}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetailScreen(item: item),
                          ),
                        ).then((_) => _refreshData());
                      },
                    ),
                  );
                },
              ),
      ],
    );
  }
  
  Widget _buildItemImage(ClothingItem item) {
    if (item.imageUrl == null) {
      return const CircleAvatar(
        child: Icon(Icons.checkroom),
      );
    }
    
    return FutureBuilder<dynamic>(
      future: _imageService.getImageData(item.imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            child: CircularProgressIndicator(),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const CircleAvatar(
            child: Icon(Icons.error),
          );
        }
        
        if (kIsWeb) {
          return CircleAvatar(
            backgroundImage: NetworkImage(snapshot.data.toString()),
          );
        } else {
          return CircleAvatar(
            backgroundImage: FileImage(snapshot.data as File),
          );
        }
      },
    );
  }
  
  Widget _buildWearSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('着用履歴', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildInfoRow('着用回数', '${_outfit.wearCount}回'),
            if (_outfit.lastWorn != null) 
              _buildInfoRow('最終着用日', _formatDate(_outfit.lastWorn!)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
  
  void _markAsWorn() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _outfitService.markOutfitAsWorn(_outfit.id);
      await _refreshData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_outfit.name}を着用済みとしてマークしました')),
        );
      }
    } catch (e) {
      print('Error marking outfit as worn: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('着用記録の更新に失敗しました: $e')),
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
  
  void _editOutfit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateOutfitScreen(outfitToEdit: _outfit),
      ),
    ).then((result) {
      if (result == true) {
        _refreshData();
      }
    });
  }
  
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('コーディネートの削除'),
        content: Text('${_outfit.name}を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteOutfit();
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _deleteOutfit() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _outfitService.removeOutfit(_outfit.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_outfit.name}を削除しました')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('Error deleting outfit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('コーディネートの削除に失敗しました: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _refreshData() async {
    try {
      final outfits = await _outfitService.getAllOutfits();
      final updatedOutfit = outfits.firstWhere(
        (o) => o.id == _outfit.id,
        orElse: () => _outfit,
      );
      
      final items = await _outfitService.getItemsInOutfit(updatedOutfit);
      
      if (mounted) {
        setState(() {
          _outfit = updatedOutfit;
          _items = items;
        });
      }
    } catch (e) {
      print('Error refreshing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データの更新に失敗しました: $e')),
        );
      }
    }
  }
}
