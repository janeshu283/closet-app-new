import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/item_list_screen.dart';
import 'screens/outfit_list_screen.dart';
import 'screens/weather_suggestion_screen.dart';
import 'theme/app_theme.dart';
import 'services/supabase_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart'; // for ScaffoldMessenger

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabaseの初期化
  await Supabase.initialize(
    url: SupabaseService.supabaseUrl,
    anonKey: SupabaseService.supabaseKey,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'My Style Closet',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja'),
        Locale('en'),
      ],
      builder: (context, child) {
        return ScaffoldMessenger(child: child!);
      },
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  
  static final List<Widget> _screens = [
    const HomeScreen(),
    const ItemListScreen(),
    const OutfitListScreen(),
    const WeatherSuggestionScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: AppTheme.primaryColor,
        inactiveColor: CupertinoColors.systemGrey,
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.checkmark_square), label: 'アイテム'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_2_square_stack), label: 'コーデ'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.sun_max), label: '天気コーデ'),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const HomeScreen();
          case 1:
            return const ItemListScreen();
          case 2:
            return const OutfitListScreen();
          case 3:
            return const WeatherSuggestionScreen();
          default:
            return const HomeScreen();
        }
      },
    );
  }
}

// Webエントリーポイント
class WebApp extends StatelessWidget {
  const WebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyApp();
  }
}
