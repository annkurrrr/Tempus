import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/session.dart';
import 'services/session_storage.dart';
import 'services/timer_notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/sessions_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/schedule_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  TimerNotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  /// Global key so children can toggle theme via MyApp.of(context).
  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadThemePref();
  }

  Future<void> _loadThemePref() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('tempus_dark_mode') ?? true;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _loaded = true;
    });
    _updateSystemUI();
  }

  /// Toggles between light and dark mode and persists the choice.
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setState(() => _themeMode = newMode);
    _updateSystemUI();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tempus_dark_mode', newMode == ThemeMode.dark);
  }

  bool get isDark => _themeMode == ThemeMode.dark;

  void _updateSystemUI() {
    final isDarkNow = _themeMode == ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkNow ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDarkNow
            ? const Color(0xFF141414)
            : Colors.white,
        systemNavigationBarIconBrightness: isDarkNow
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Tempus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: const _AppShell(),
    );
  }
}

/// Root shell that holds the bottom navigation and all screens.
class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;
  List<Session> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await SessionStorage.loadSessions();
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(
          key: const ValueKey('home'),
          sessions: _sessions,
          onSessionSaved: _loadSessions,
        );
      case 1:
        return SessionsScreen(
          key: const ValueKey('sessions'),
          sessions: _sessions,
          onSessionDeleted: _loadSessions,
        );
      case 2:
        return const GoalsScreen(key: ValueKey('goals'));
      case 3:
        return const ScheduleScreen(key: ValueKey('schedule'));
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: c.surfaceLighter.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined),
              activeIcon: Icon(Icons.timer),
              label: 'Timer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Sessions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flag_outlined),
              activeIcon: Icon(Icons.flag),
              label: 'Goals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Schedule',
            ),
          ],
        ),
      ),
    );
  }
}
