import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  
  factory WeatherService() {
    return _instance;
  }
  
  WeatherService._internal();
  
  // 現在の天気データをキャッシュ
  WeatherData? _currentWeather;
  List<WeatherData> _forecastWeather = [];
  
  // 位置情報
  String _location = '東京';
  
  // 天気APIキー（実際のアプリでは環境変数などで管理）
  // 注意: このキーは仮のものです。実際の開発では適切なAPIキーを使用してください。
  final String _apiKey = 'your_api_key_here';
  
  // 位置情報の設定
  Future<void> setLocation(String location) async {
    _location = location;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weather_location', location);
    
    // 新しい位置情報で天気を更新
    await fetchWeatherData();
  }
  
  // 位置情報の取得
  String getLocation() {
    return _location;
  }
  
  // 保存された位置情報の読み込み
  Future<void> loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _location = prefs.getString('weather_location') ?? '東京';
  }
  
  // 現在の天気データを取得
  Future<WeatherData> getCurrentWeather() async {
    if (_currentWeather == null) {
      await fetchWeatherData();
    }
    
    // 天気データが取得できなかった場合はモックデータを返す
    return _currentWeather ?? WeatherData.getMockData();
  }
  
  // 天気予報データを取得
  Future<List<WeatherData>> getForecastWeather() async {
    if (_forecastWeather.isEmpty) {
      await fetchWeatherData();
    }
    
    return _forecastWeather;
  }
  
  // 天気データをAPIから取得（実際のアプリではここで外部APIを呼び出す）
  Future<void> fetchWeatherData() async {
    try {
      // 開発段階ではモックデータを使用
      _currentWeather = WeatherData.getMockData();
      
      // 5日間の予報データを生成（モック）
      _forecastWeather = List.generate(5, (index) {
        final date = DateTime.now().add(Duration(days: index));
        final conditions = ['晴れ', '曇り', '雨', '雪'];
        final condition = conditions[index % conditions.length];
        
        return WeatherData(
          condition: condition,
          temperature: 20 + (index - 2),
          humidity: 60 + (index * 2),
          windSpeed: 3 + (index * 0.5),
          date: date,
          locationName: _location,
        );
      });
      
      // 実際のアプリでは以下のようなAPIコールを行う
      /*
      final url = 'https://api.example.com/weather?location=$_location&apiKey=$_apiKey';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentWeather = WeatherData.fromJson(data['current']);
        _forecastWeather = (data['forecast'] as List)
            .map((item) => WeatherData.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to load weather data');
      }
      */
      
      // 天気データをキャッシュに保存
      await _cacheWeatherData();
    } catch (e) {
      print('Error fetching weather data: $e');
      // エラー時にキャッシュから読み込み
      await _loadCachedWeatherData();
    }
  }
  
  // 天気データをキャッシュに保存
  Future<void> _cacheWeatherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_currentWeather != null) {
        await prefs.setString('current_weather', jsonEncode(_currentWeather!.toJson()));
      }
      
      if (_forecastWeather.isNotEmpty) {
        final forecastJson = _forecastWeather.map((w) => w.toJson()).toList();
        await prefs.setString('forecast_weather', jsonEncode(forecastJson));
      }
    } catch (e) {
      print('Error caching weather data: $e');
    }
  }
  
  // キャッシュから天気データを読み込み
  Future<void> _loadCachedWeatherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final currentWeatherJson = prefs.getString('current_weather');
      if (currentWeatherJson != null) {
        _currentWeather = WeatherData.fromJson(jsonDecode(currentWeatherJson));
      }
      
      final forecastWeatherJson = prefs.getString('forecast_weather');
      if (forecastWeatherJson != null) {
        final List<dynamic> forecastList = jsonDecode(forecastWeatherJson);
        _forecastWeather = forecastList
            .map((item) => WeatherData.fromJson(item))
            .toList();
      }
    } catch (e) {
      print('Error loading cached weather data: $e');
      // キャッシュからの読み込みに失敗した場合はモックデータを使用
      _currentWeather = WeatherData.getMockData();
      _forecastWeather = List.generate(5, (index) {
        return WeatherData(
          condition: index % 2 == 0 ? '晴れ' : '曇り',
          temperature: 20 + (index - 2),
          humidity: 60,
          windSpeed: 3,
          date: DateTime.now().add(Duration(days: index)),
          locationName: _location,
        );
      });
    }
  }
  
  // 天気に基づいたコーディネート提案
  Future<Map<String, dynamic>> getWeatherBasedSuggestions() async {
    final weather = await getCurrentWeather();
    
    return {
      'weather': weather,
      'suggestedCategories': weather.getSuggestedCategories(),
      'suggestedColors': weather.getSuggestedColors(),
      'season': weather.getSeason(),
    };
  }
}
