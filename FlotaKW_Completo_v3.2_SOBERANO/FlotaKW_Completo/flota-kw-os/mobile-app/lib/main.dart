import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/alta_screen.dart';
import 'screens/admin_screen.dart';

void main() {
  runApp(const FlotaKWApp());
}

class FlotaKWApp extends StatelessWidget {
  const FlotaKWApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlotaKW OS v3.0',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.black, brightness: Brightness.light), appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.white)),
      home: const HomeShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int idx = 0;
  final screens = [const DashboardScreen(), const AltaScreen(), const AdminScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: "Dashboard"),
          NavigationDestination(icon: Icon(Icons.add_box), label: "Alta Atomica"),
          NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: "Admin"),
        ],
      ),
    );
  }
}
