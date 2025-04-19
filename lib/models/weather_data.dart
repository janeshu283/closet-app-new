class WeatherData {
  final String condition; // 晴れ、曇り、雨、雪など
  final double temperature; // 気温（摂氏）
  final double humidity; // 湿度（%）
  final double windSpeed; // 風速（m/s）
  final DateTime date; // 日付
  final String locationName; // 場所の名前
  
  WeatherData({
    required this.condition,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.date,
    required this.locationName,
  });
  
  // 天気の状態に基づいて適切な服装のカテゴリを提案
  List<String> getSuggestedCategories() {
    final List<String> categories = [];
    
    // 気温に基づく基本的な服装提案
    if (temperature < 5) {
      // 寒い：厚手のアウター、セーター、長袖
      categories.add('アウター');
      categories.add('トップス');
      categories.add('ボトムス');
    } else if (temperature < 15) {
      // 涼しい：ライトアウター、長袖
      categories.add('アウター');
      categories.add('トップス');
      categories.add('ボトムス');
    } else if (temperature < 25) {
      // 穏やか：長袖または半袖
      categories.add('トップス');
      categories.add('ボトムス');
    } else {
      // 暑い：半袖、軽装
      categories.add('トップス');
      categories.add('ボトムス');
    }
    
    // 天気の状態に基づく追加提案
    if (condition == '雨') {
      categories.add('アウター'); // レインコートなど
      categories.add('シューズ'); // 防水靴
    } else if (condition == '雪') {
      categories.add('アウター');
      categories.add('シューズ'); // 防寒・防滑靴
    }
    
    // 風が強い場合
    if (windSpeed > 5.0) {
      if (!categories.contains('アウター')) {
        categories.add('アウター');
      }
    }
    
    // アクセサリーは常に提案
    categories.add('アクセサリー');
    
    return categories;
  }
  
  // 天気に適した色を提案
  List<String> getSuggestedColors() {
    final List<String> colors = [];
    
    switch (condition) {
      case '晴れ':
        colors.addAll(['白', '青', '黄', 'オレンジ', 'ピンク']);
        break;
      case '曇り':
        colors.addAll(['グレー', 'ネイビー', 'パープル', 'ベージュ']);
        break;
      case '雨':
        colors.addAll(['ネイビー', '青', 'グレー', 'ブラウン']);
        break;
      case '雪':
        colors.addAll(['白', 'グレー', 'ネイビー', 'パープル']);
        break;
      default:
        colors.addAll(['白', '黒', 'ベージュ', 'ネイビー']); // 無難な色
    }
    
    return colors;
  }
  
  // 天気データからシーズン（季節）を判断
  String getSeason() {
    final int month = date.month;
    
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
  
  // JSON変換メソッド
  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'date': date.toIso8601String(),
      'locationName': locationName,
    };
  }
  
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      condition: json['condition'],
      temperature: json['temperature'],
      humidity: json['humidity'],
      windSpeed: json['windSpeed'],
      date: DateTime.parse(json['date']),
      locationName: json['locationName'],
    );
  }
  
  // モックデータの生成（開発用）
  static WeatherData getMockData() {
    return WeatherData(
      condition: '晴れ',
      temperature: 22.5,
      humidity: 65.0,
      windSpeed: 3.2,
      date: DateTime.now(),
      locationName: '東京',
    );
  }
}
