import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/outfit.dart';
import '../models/clothing_item.dart';
import '../services/outfit_service_supabase.dart';
import '../services/closet_service_supabase.dart';
import '../services/image_service.dart';

class CreateOutfitScreen extends StatefulWidget {
  final Outfit? outfitToEdit;

  const CreateOutfitScreen({
    super.key,
    this.outfitToEdit,
  });

  @override
  State<CreateOutfitScreen> createState() => _CreateOutfitScreenState();
}

class _CreateOutfitScreenState extends State<CreateOutfitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  
  final OutfitServiceSupabase _outfitService = OutfitServiceSupabase();
  final ClosetServiceSupabase _closetService = ClosetServiceSupabase();
  final ImageService _imageService = ImageService();
  
  String? _selectedSeason;
  String? _selectedOccasion;
  List<ClothingItem> _selectedItems = [];
  bool _isLoading = false;
  
  final List<String> _seasons = ['春', '夏', '秋', '冬'];
  final List<String> _occasions = ['カジュアル', 'フォーマル', 'スポーツ', 'オフィス', 'パーティー'];
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 編集モードの場合、既存のデータをフォームに設定
      if (widget.outfitToEdit != null) {
        final outfit = widget.outfitToEdit!;
        _nameController.text = outfit.name;
        _selectedSeason = outfit.season;
        _selectedOccasion = outfit.occasion;
        if (outfit.notes != null) {
          _notesController.text = outfit.notes!;
        }
        
        // 選択されたアイテムを取得
        _selectedItems = await _outfitService.getItemsInOutfit(outfit);
      }
    } catch (e) {
      print('Error loading initial data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データの読み込みに失敗しました: $e')),
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
  
  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.outfitToEdit != null ? 'コーディネート編集' : 'コーディネート作成'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'コーディネート名 *',
                      hintText: '例：休日カジュアル',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'コーディネート名を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '季節',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedSeason,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('選択なし'),
                      ),
                      ..._seasons.map((season) {
                        return DropdownMenuItem(
                          value: season,
                          child: Text(season),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSeason = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '場面',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedOccasion,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('選択なし'),
                      ),
                      ..._occasions.map((occasion) {
                        return DropdownMenuItem(
                          value: occasion,
                          child: Text(occasion),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedOccasion = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'メモ',
                      hintText: '例：雨の日用、旅行用など',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSelectedItemsSection(),
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: _showItemSelectionDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('アイテムを追加'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSelectedItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('選択したアイテム', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${_selectedItems.length}アイテム', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        
        _selectedItems.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'アイテムが選択されていません\n「アイテムを追加」ボタンからアイテムを選択してください',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedItems.length,
                itemBuilder: (context, index) {
                  final item = _selectedItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: _buildItemImage(item),
                      title: Text(item.name),
                      subtitle: Text('${item.category} • ${item.color}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedItems.removeAt(index);
                          });
                        },
                        tooltip: '削除',
                      ),
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
  
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveOutfit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator() 
                : const Text('保存', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showItemSelectionDialog() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final allItems = await _closetService.getAllItems();
      final Map<String, List<ClothingItem>> categorizedItems = {};
      
      // アイテムをカテゴリごとに分類
      for (final item in allItems) {
        if (!categorizedItems.containsKey(item.category)) {
          categorizedItems[item.category] = [];
        }
        categorizedItems[item.category]!.add(item);
      }
      
      // 既に選択されているアイテムのIDリスト
      final selectedItemIds = _selectedItems.map((item) => item.id).toSet();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // 全カテゴリを初期展開
        _expandedCategories
          ..clear()
          ..addEntries(
            categorizedItems.keys.map((key) => MapEntry(key, true)),
          );
        _showItemSelectionDialogUI(categorizedItems, selectedItemIds);
      }
    } catch (e) {
      print('Error loading items for selection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アイテムの読み込みに失敗しました: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showItemSelectionDialogUI(Map<String, List<ClothingItem>> categorizedItems, Set<dynamic> selectedItemIds) {
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('アイテムを選択'),
            content: SizedBox(
              width: double.maxFinite,
              child: categorizedItems.isEmpty
                  ? const Center(child: Text('アイテムがありません'))
                  : SingleChildScrollView(
                      child: Column(
                        children: categorizedItems.entries.map((entry) {
                          final category = entry.key;
                          final items = entry.value;
                          return ExpansionTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(category),
                                Text('${items.length}アイテム', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                            initiallyExpanded: _expandedCategories[category] ?? false,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _expandedCategories[category] = expanded;
                              });
                            },
                            children: items.map((item) {
                              final isSelected = selectedItemIds.contains(item.id);
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(item.name),
                                subtitle: Text('${item.color}${item.brand != null ? ' • ${item.brand}' : ''}'),
                                secondary: _buildItemImage(item),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      if (!selectedItemIds.contains(item.id)) {
                                        selectedItemIds.add(item.id);
                                        _selectedItems.add(item);
                                      }
                                    } else {
                                      selectedItemIds.remove(item.id);
                                      _selectedItems.removeWhere((i) => i.id == item.id);
                                    }
                                  });
                                  this.setState(() {});
                                },
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('閉じる'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // カテゴリの展開状態を管理
  final Map<String, bool> _expandedCategories = {
    'トップス': true,
    'ボトムス': true,
    'アウター': false,
    'シューズ': false,
    'アクセサリー': false,
  };
  
  void _saveOutfit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('少なくとも1つのアイテムを選択してください')),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        final itemIds = _selectedItems.map((item) => item.id).toList();
        
        if (widget.outfitToEdit != null) {
          // 既存のコーディネートを更新
          final updatedOutfit = Outfit(
            id: widget.outfitToEdit!.id,
            name: _nameController.text,
            itemIds: itemIds,
            createdAt: widget.outfitToEdit!.createdAt,
            lastWorn: widget.outfitToEdit!.lastWorn,
            wearCount: widget.outfitToEdit!.wearCount,
            season: _selectedSeason,
            occasion: _selectedOccasion,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );
          
          await _outfitService.updateOutfit(updatedOutfit);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('コーディネート「${updatedOutfit.name}」を更新しました')),
            );
            Navigator.of(context).pop(true);
          }
        } else {
          // 新しいコーディネートを作成
          final newOutfit = Outfit(
            name: _nameController.text,
            itemIds: itemIds,
            season: _selectedSeason,
            occasion: _selectedOccasion,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );
          
          final savedOutfit = await _outfitService.addOutfit(newOutfit);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('コーディネート「${savedOutfit.name}」を作成しました')),
            );
            Navigator.of(context).pop(true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('コーディネートの保存に失敗しました: $e')),
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
  }
}
