import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';

class ItemCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback? onTap;
  final VoidCallback? onWear;
  final bool showActions;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onWear,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final imageService = ImageService();
    final categoryColor = AppTheme.getCategoryColor(item.category);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像セクション
            AspectRatio(
              aspectRatio: 1.5,
              child: item.imageUrl != null
                  ? FutureBuilder<dynamic>(
                      future: imageService.getImageData(item.imageUrl),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
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
            
            // カテゴリバッジ
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // 情報セクション
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '色: ${item.color}${item.brand != null ? ' • ${item.brand}' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showActions) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.repeat,
                              size: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.wearCount}回着用',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        if (onWear != null)
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            color: AppTheme.primaryColor,
                            onPressed: onWear,
                            tooltip: '着用済みとしてマーク',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaceholder(Color color) {
    return Container(
      color: color.withOpacity(0.2),
      child: Center(
        child: Icon(
          AppTheme.getCategoryIcon(item.category),
          size: 48,
          color: color,
        ),
      ),
    );
  }
}
