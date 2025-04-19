import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import '../models/clothing_item.dart';
import '../services/closet_service_supabase.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';

class AddItemScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialImagePath;
  final ClothingItem? itemToEdit;

  const AddItemScreen({
    super.key,
    this.initialCategory,
    this.initialImagePath,
    this.itemToEdit,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _sizeController = TextEditingController();
  final _materialController = TextEditingController();

  String _selectedCategory = '';
  String _selectedColor = '';
  String? _imagePath;
  bool _isLoading = false;
  bool _isEditMode = false;

  final ImageService _imageService = ImageService();
  final ClosetServiceSupabase _closetService = ClosetServiceSupabase();

  final List<String> _categories = ['Tシャツ', 'シャツ', 'パーカー', 'アウター', 'パンツ', 'シューズ', 'アクセサリー'];

  final List<String> _colors = [
    '白', '黒', '赤', '青', '緑', '黄', 'ピンク', 'パープル',
    'グレー', 'ベージュ', 'ブラウン', 'ネイビー', 'オレンジ', 'ターコイズ'
  ];

  @override
  void initState() {
    super.initState();

    // 編集モードかどうかを設定
    _isEditMode = widget.itemToEdit != null;

    if (_isEditMode) {
      // 編集モードの場合、既存のアイテム情報をフォームに設定
      final item = widget.itemToEdit!;
      _nameController.text = item.name;
      _selectedCategory = item.category;
      _selectedColor = item.color;
      _imagePath = item.imageUrl;

      if (item.brand != null) {
        _brandController.text = item.brand!;
      }

      if (item.size != null) {
        _sizeController.text = item.size!;
      }

      if (item.material != null) {
        _materialController.text = item.material!;
      }
    } else {
      // 新規作成モードの場合、初期カテゴリと初期画像を設定
      _selectedCategory = widget.initialCategory ?? _categories[0];
      _selectedColor = _colors[0];
      _imagePath = widget.initialImagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppTheme.getCategoryColor(_selectedCategory);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isEditMode ? 'アイテム編集' : 'アイテム追加'),
        trailing: _isEditMode
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.delete),
                onPressed: _confirmDelete,
              )
            : null,
      ),
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 画像セクション
                        _buildImageSection(categoryColor),

                        // 入力フォーム
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 必須情報セクション
                              _buildSectionTitle('基本情報', Icons.info_outline),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'アイテム名 *',
                                  hintText: '例：白Tシャツ',
                                  prefixIcon: const Icon(Icons.label),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'アイテム名を入力してください';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // カテゴリ選択
                              _buildCategorySelector(),
                              const SizedBox(height: 16),

                              // 色選択
                              _buildColorSelector(),
                              const SizedBox(height: 24),

                              // 追加情報セクション
                              _buildSectionTitle('追加情報', Icons.more_horiz),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _brandController,
                                decoration: InputDecoration(
                                  labelText: 'ブランド',
                                  hintText: '例：ユニクロ',
                                  prefixIcon: const Icon(Icons.business),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _sizeController,
                                decoration: InputDecoration(
                                  labelText: 'サイズ',
                                  hintText: '例：M',
                                  prefixIcon: const Icon(Icons.straighten),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _materialController,
                                decoration: InputDecoration(
                                  labelText: '素材',
                                  hintText: '例：コットン',
                                  prefixIcon: const Icon(Icons.layers),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 保存ボタン
                _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
                color: AppTheme.primaryColor,
              ),
        ),
      ],
    );
  }

  Widget _buildImageSection(Color categoryColor) {
    return Stack(
      children: [
        // 画像プレビュー
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
          ),
          child: _imagePath != null
              ? FutureBuilder<dynamic>(
                  future: _imageService.getImageData(_imagePath),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CupertinoActivityIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      return _buildPlaceholder(categoryColor);
                    }

                    if (kIsWeb) {
                      return Image.network(
                        snapshot.data.toString(),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    } else {
                      return Image.file(
                        snapshot.data as File,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    }
                  },
                )
              : _buildPlaceholder(categoryColor),
        ),

        // カメラ・ギャラリーボタン
        Positioned(
          bottom: 16,
          right: 16,
          child: Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                onPressed: _takePicture,
                child: Icon(CupertinoIcons.camera, color: categoryColor),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                onPressed: _pickImage,
                child: Icon(CupertinoIcons.photo, color: categoryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AppTheme.getCategoryIcon(_selectedCategory),
            size: 64,
            color: color.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'タップして画像を追加',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'カテゴリ *',
          style: TextStyle(
            color: CupertinoTheme.of(context).textTheme.textStyle.color!,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              final categoryColor = AppTheme.getCategoryColor(category);

              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCategory = category),
                selectedColor: categoryColor.withOpacity(0.2),
                backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? categoryColor
                      : CupertinoTheme.of(context).textTheme.textStyle.color!,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '色 *',
          style: TextStyle(
            color: CupertinoTheme.of(context).textTheme.textStyle.color!,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: CupertinoTheme.of(context).barBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CupertinoTheme.of(context).textTheme.textStyle.color!.withOpacity(0.2)),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _colors.length,
            itemBuilder: (context, index) {
              final color = _colors[index];
              final isSelected = _selectedColor == color;

              // 色に対応するマテリアルカラーを取得
              Color displayColor = _getColorFromName(color);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: displayColor,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: CupertinoTheme.of(context).textTheme.textStyle.color!, width: 2)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: CupertinoTheme.of(context).textTheme.textStyle.color!.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          CupertinoIcons.check_mark,
                          color: CupertinoTheme.of(context).barBackgroundColor,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '選択中: $_selectedColor',
            style: TextStyle(
              color: CupertinoTheme.of(context).textTheme.textStyle.color!,
            ),
          ),
        ),
      ],
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

  Widget _buildBottomBar() {
    final categoryColor = AppTheme.getCategoryColor(_selectedCategory);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: CupertinoTheme.of(context).textTheme.textStyle.color!.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: CupertinoButton(
          color: categoryColor,
          disabledColor: CupertinoColors.inactiveGray,
          borderRadius: BorderRadius.circular(8.0),
          onPressed: _isLoading ? null : _saveItem,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : Text(
                  _isEditMode ? '更新' : '保存',
                  style: const TextStyle(color: CupertinoColors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      final imagePath = await _imageService.takePicture();
      if (imagePath != null) {
        setState(() {
          _imagePath = imagePath;
        });
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('エラー'),
            content: Text('カメラの起動に失敗しました: $e'),
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

  Future<void> _pickImage() async {
    try {
      final imagePath = await _imageService.pickImageFromGallery();
      if (imagePath != null) {
        setState(() {
          _imagePath = imagePath;
        });
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('エラー'),
            content: Text('画像の選択に失敗しました: $e'),
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

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_isEditMode) {
          // 既存のアイテムを更新
          final updatedItem = ClothingItem(
            id: widget.itemToEdit!.id,
            name: _nameController.text,
            category: _selectedCategory,
            color: _selectedColor,
            imageUrl: _imagePath,
            dateAdded: widget.itemToEdit!.dateAdded,
            brand: _brandController.text.isNotEmpty ? _brandController.text : null,
            size: _sizeController.text.isNotEmpty ? _sizeController.text : null,
            material: _materialController.text.isNotEmpty ? _materialController.text : null,
            wearCount: widget.itemToEdit!.wearCount,
            lastWorn: widget.itemToEdit!.lastWorn,
          );

          await _closetService.updateItem(updatedItem);

          if (mounted) {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('アイテム更新'),
                content: Text('アイテム「${updatedItem.name}」を更新しました'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          // 新しいアイテムを追加
          final newItem = ClothingItem(
            name: _nameController.text,
            category: _selectedCategory,
            color: _selectedColor,
            imageUrl: _imagePath,
            brand: _brandController.text.isNotEmpty ? _brandController.text : null,
            size: _sizeController.text.isNotEmpty ? _sizeController.text : null,
            material: _materialController.text.isNotEmpty ? _materialController.text : null,
          );

          final savedItem = await _closetService.addItem(newItem);

          if (mounted) {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('アイテム追加'),
                content: Text('アイテム「${savedItem.name}」を追加しました'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('エラー'),
              content: Text('アイテムの保存に失敗しました: $e'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(context).pop(),
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
          });
        }
      }
    }
  }

  void _confirmDelete() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('アイテムの削除'),
        content: Text('${widget.itemToEdit!.name}を削除してもよろしいですか？'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteItem();
            },
            isDestructiveAction: true,
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _deleteItem() async {
    if (widget.itemToEdit != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _closetService.removeItem(widget.itemToEdit!.id);

        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('アイテム削除'),
              content: Text('${widget.itemToEdit!.name}を削除しました'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('エラー'),
              content: Text('アイテムの削除に失敗しました: $e'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(context).pop(),
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
          });
        }
      }
    }
  }
}
