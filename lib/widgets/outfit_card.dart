import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/outfit.dart';
import '../models/clothing_item.dart';
import '../services/outfit_service.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';

class OutfitCard extends StatelessWidget {
  final Outfit outfit;
  final VoidCallback? onTap;
  final VoidCallback? onWear;
  final bool showActions;

  const OutfitCard({
    super.key,
    required this.outfit,
    this.onTap,
    this.onWear,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final outfitService = OutfitService();
    final imageService = ImageService();
    final items = outfitService.getItemsInOutfit(outfit);
    final seasonColor = outfit.season != null ? AppTheme.getSeasonColor(outfit.season!) : null;

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
              child: _buildOutfitPreview(items, imageService),
            ),
            
            // 季節バッジ
            if (outfit.season != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: seasonColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    outfit.season!,
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
                    outfit.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${items.length}アイテム${outfit.occasion != null ? ' • ${outfit.occasion}' : ''}',
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
                              '${outfit.wearCount}回着用',
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
  
  Widget _buildOutfitPreview(List<ClothingItem> items, ImageService imageService) {
    if (items.isEmpty) {
      return Container(
        color: Colors.grey.withOpacity(0.2),
        child: const Center(
          child: Icon(
            Icons.style,
            size: 48,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    // 最初のアイテムの画像を表示
    final firstItem = items.first;
    if (firstItem.imageUrl == null) {
      return Container(
        color: AppTheme.getCategoryColor(firstItem.category).withOpacity(0.2),
        child: Center(
          child: Icon(
            AppTheme.getCategoryIcon(firstItem.category),
            size: 48,
            color: AppTheme.getCategoryColor(firstItem.category),
          ),
        ),
      );
    }
    
    return Stack(
      children: [
        // メイン画像
        FutureBuilder<dynamic>(
          future: imageService.getImageData(firstItem.imageUrl),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return Container(
                color: AppTheme.getCategoryColor(firstItem.category).withOpacity(0.2),
                child: Center(
                  child: Icon(
                    AppTheme.getCategoryIcon(firstItem.category),
                    size: 48,
                    color: AppTheme.getCategoryColor(firstItem.category),
                  ),
                ),
              );
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
        ),
        
        // アイテム数バッジ
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${items.length}アイテム',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
