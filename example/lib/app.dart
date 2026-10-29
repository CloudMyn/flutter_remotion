import 'package:flutter/material.dart';

import 'screens/comprehensive_demo_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/showcase_screen.dart';

class LaminarExampleApp extends StatelessWidget {
  const LaminarExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laminar — Programmatic Motion & Video',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0D0D12),
        cardColor: const Color(0xFF17172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0D12),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ComprehensiveDemoScreen(),
    ShowcaseScreen(),
    GalleryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: const Color(0xFF10101C),
          indicatorColor: const Color(0xFF6C63FF).withValues(alpha: 0.3),
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.science_outlined),
              selectedIcon: Icon(Icons.science, color: Color(0xFF6C63FF)),
              label: 'Fitur Menyeluruh',
            ),
            NavigationDestination(
              icon: Icon(Icons.widgets_outlined),
              selectedIcon: Icon(Icons.widgets, color: Color(0xFF6C63FF)),
              label: 'Showcase',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view, color: Color(0xFF6C63FF)),
              label: 'Gallery',
            ),
          ],
        ),
      ),
    );
  }
}
