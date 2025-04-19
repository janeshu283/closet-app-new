import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../models/weather_data.dart';
import '../services/closet_service_supabase.dart';
import '../services/outfit_service_supabase.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import 'outfit_detail_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;

class WeatherSuggestionScreen extends StatefulWidget {
  const WeatherSuggestionScreen({super.key});

  @override
  State<WeatherSuggestionScreen> createState() => _WeatherSuggestionScreenState();
}

class _WeatherSuggestionScreenState extends State<WeatherSuggestionScreen> {
  final WeatherService _weatherService = WeatherService();
  final ClosetServiceSupabase _closetService = ClosetServiceSupabase();
  final OutfitServiceSupabase _outfitService = OutfitServiceSupabase();
  
  WeatherData? _currentWeather;
  List<WeatherData> _forecastWeather = [];
  List<ClothingItem> _suggestedItems = [];
  List<Outfit> _suggestedOutfits = [];
  
  bool _isLoading = true;
  String _location = '東京';
  int _selectedDayIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 位置情報の読み込み
      await _weatherService.loadLocation();
      _location = _weatherService.getLocation();
      
      // 天気データの取得
      _currentWeather = await _weatherService.getCurrentWeather();
      _forecastWeather = await _weatherService.getForecastWeather();
      
      // 天気に基づいた提案の取得
      final suggestions = await _weatherService.getWeatherBasedSuggestions();
      final suggestedCategories = suggestions['suggestedCategories'] as List<String>;
      final suggestedColors = suggestions['suggestedColors'] as List<String>;
      
      // カテゴリと色に基づいてアイテムを提案
      _suggestedItems = await _getItemsByCategoriesAndColors(
        suggestedCategories,
        suggestedColors,
      );
      
      // 提案されたアイテムからコーディネートを生成
      _suggestedOutfits = await _generateOutfitSuggestions(_suggestedItems);
      
    } catch (e) {
      print('Error loading weather data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<List<ClothingItem>> _getItemsByCategoriesAndColors(
    List<String> categories,
    List<String> colors,
  ) async {
    try {
      final allItems = await _closetService.getAllItems();
      
      // カテゴリと色でフィルタリング
      return allItems.where((item) {
        return categories.contains(item.category) && colors.contains(item.color);
      }).toList();
    } catch (e) {
      print('Error getting items by categories and colors: $e');
      return [];
    }
  }
  
  Future<List<Outfit>> _generateOutfitSuggestions(List<ClothingItem> items) async {
    try {
      // 既存のコーディネートから天気に合うものを探す
      final allOutfits = await _outfitService.getAllOutfits();
      final weatherSuitableOutfits = <Outfit>[];
      
      for (final outfit in allOutfits) {
        final outfitItems = await _outfitService.getItemsInOutfit(outfit);
        
        // コーディネートのアイテムが提案されたアイテムに含まれているかチェック
        final containsSuggestedItems = outfitItems.any((item) => 
          items.any((suggestedItem) => suggestedItem.id == item.id)
        );
        
        if (containsSuggestedItems) {
          weatherSuitableOutfits.add(outfit);
        }
      }
      
      // 既存のコーディネートがあればそれを返す
      if (weatherSuitableOutfits.isNotEmpty) {
        return weatherSuitableOutfits.take(3).toList();
      }
    
      // 新しいコーディネートを生成
      final topItems = items.where((item) => item.category == 'トップス').toList();
      final bottomItems = items.where((item) => item.category == 'ボトムス').toList();
      final outerItems = items.where((item) => item.category == 'アウター').toList();
      final shoeItems = items.where((item) => item.category == 'シューズ').toList();
      
      final generatedOutfits = <Outfit>[];
      
      // トップスとボトムスの組み合わせでコーディネートを生成
      if (topItems.isNotEmpty && bottomItems.isNotEmpty) {
        for (int i = 0; i < topItems.length && i < 2; i++) {
          for (int j = 0; j < bottomItems.length && j < 2; j++) {
            final outfitItems = <ClothingItem>[topItems[i], bottomItems[j]];
            
            // アウターがあれば追加
            if (outerItems.isNotEmpty && _currentWeather != null && _currentWeather!.temperature < 20) {
              outfitItems.add(outerItems.first);
            }
            
            // シューズがあれば追加
            if (shoeItems.isNotEmpty) {
              outfitItems.add(shoeItems.first);
            }
            
            // コーディネート名を生成
            final weatherCondition = _currentWeather?.condition ?? '晴れ';
            final outfitName = '${weatherCondition}の日のコーディネート ${generatedOutfits.length + 1}';
            
            // コーディネートを生成
            final outfit = Outfit(
              name: outfitName,
              itemIds: outfitItems.map((item) => item.id as String).toList(),
              createdAt: DateTime.now(),
              season: _getSeason(),
              occasion: 'カジュアル',
            );
            
            generatedOutfits.add(outfit);
            
            // 最大3つまで生成
            if (generatedOutfits.length >= 3) {
              break;
            }
          }
          
          if (generatedOutfits.length >= 3) {
            break;
          }
        }
      }
      
      return generatedOutfits;
    } catch (e) {
      print('Error generating outfit suggestions: $e');
      return [];
    }
  }
  
  String _getSeason() {
    final now = DateTime.now();
    final month = now.month;
    
    if (month >= 3 && month <= 5) {
      return '春';
    } else if (month >= 6 && month <= 8) {
      return '夏';
    } else if (month >= 9 && month <= 11) {
      return '秋';
    } else {
      return '冬';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('My Style 天気コーデ'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: _loadData,
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _buildContent(),
      ),
    );
  }
  
  Widget _buildContent() {
    if (_currentWeather == null) {
      return const Center(
        child: Text('天気データを取得できませんでした'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 現在の天気
          _buildCurrentWeather(),
          
          // 天気予報
          _buildWeatherForecast(),
          
          // 提案されたコーディネート
          if (_suggestedOutfits.isNotEmpty)
            _buildSuggestedOutfits(),
          
          // 提案されたアイテム
          if (_suggestedItems.isNotEmpty)
            _buildSuggestedItems(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildCurrentWeather() {
    final weather = _selectedDayIndex == 0
        ? _currentWeather!
        : _forecastWeather[_selectedDayIndex - 1];
    
    final weatherIcon = AppTheme.getWeatherIcon(weather.condition);
    final seasonIcon = AppTheme.getSeasonIcon(weather.getSeason());
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _location,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(weather.date)} (${_getDayOfWeek(weather.date)})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    seasonIcon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    weather.getSeason(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    weatherIcon,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.condition,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${weather.temperature.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.water_drop,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '湿度: ${weather.humidity.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.air,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '風速: ${weather.windSpeed.toStringAsFixed(1)}m/s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeatherForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '5日間の天気予報',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 8, right: 8),
            itemCount: _forecastWeather.length + 1, // 今日 + 予報
            itemBuilder: (context, index) {
              final isToday = index == 0;
              final weather = isToday
                  ? _currentWeather!
                  : _forecastWeather[index - 1];
              
              final isSelected = _selectedDayIndex == index;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDayIndex = index;
                  });
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
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
                      Text(
                        isToday ? '今日' : _getDayOfWeek(weather.date),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        AppTheme.getWeatherIcon(weather.condition),
                        color: isSelected ? Colors.white : AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${weather.temperature.toStringAsFixed(0)}°C',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
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
  
  Widget _buildSuggestedOutfits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            children: [
              Icon(
                AppTheme.getWeatherIcon(_currentWeather?.condition ?? '晴れ'),
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'おすすめコーディネート',
                style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: _suggestedOutfits.isEmpty
            ? const Center(child: Text('提案されたコーディネートがありません'))
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestedOutfits.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final outfit = _suggestedOutfits[index];
                  // 非同期処理のため、アイテムの表示は別で行う
                  return FutureBuilder<List<ClothingItem>>(
                    future: _outfitService.getItemsInOutfit(outfit),
                    builder: (context, snapshot) {
                      final outfitItems = snapshot.data ?? [];
                      
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => OutfitDetailScreen(outfit: outfit),
                            ),
                          );
                        },
                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                              // コーディネート画像
                              Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Center(
                                  child: outfitItems.isEmpty
                                      ? const Icon(
                                          Icons.style,
                                          size: 48,
                                          color: AppTheme.primaryColor,
                                        )
                                      : GridView.count(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 3.0,
                                          crossAxisSpacing: 3.0,
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          padding: EdgeInsets.zero,
                                          children: outfitItems
                                              .take(4)
                                              .map((item) => Container(
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.getCategoryColor(item.category).withOpacity(0.2),
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        AppTheme.getCategoryIcon(item.category),
                                                        color: AppTheme.getCategoryColor(item.category),
                                                        size: 32,
                                                      ),
                                                    ),
                                                  ))
                                              .toList(),
                                        ),
                                ),
                              ),
                      
                              // コーディネート情報
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      outfit.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          AppTheme.getWeatherIcon(_currentWeather?.condition ?? '晴れ'),
                                          color: AppTheme.primaryColor,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _currentWeather?.condition ?? '晴れ',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${outfitItems.length}アイテム',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
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
                    },
                  );
                },
              ),
        ),
      ],
    );
  }
  
  Widget _buildSuggestedItems() {
    // カテゴリごとにアイテムをグループ化
    final Map<String, List<ClothingItem>> itemsByCategory = {};
    for (final item in _suggestedItems.isEmpty ? [] : _suggestedItems) {
      if (!itemsByCategory.containsKey(item.category)) {
        itemsByCategory[item.category] = [];
      }
      itemsByCategory[item.category]!.add(item);
    }
    
    if (itemsByCategory.isEmpty) {
      return const SizedBox();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            children: [
              const Icon(
                Icons.checkroom,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'おすすめアイテム',
                style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
              ),
            ],
          ),
        ),
        
        // カテゴリごとにアイテムを表示
        ...itemsByCategory.entries.map((entry) {
          final category = entry.key;
          final items = entry.value;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      AppTheme.getCategoryIcon(category),
                      color: AppTheme.getCategoryColor(category),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: () {
                        // アイテム詳細画面に遷移
                      },
                      child: Container(
                        width: 100,
                        margin: EdgeInsets.zero,
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
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.getCategoryColor(category).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  AppTheme.getCategoryIcon(category),
                                  color: AppTheme.getCategoryColor(category),
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
        }).toList(),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
  
  String _getDayOfWeek(DateTime date) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[date.weekday - 1];
  }
}
