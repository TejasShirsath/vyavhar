import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'billing/bills_list_screen.dart';
import 'home/home_screen.dart';
import 'inventory/inventory_screen.dart';
import 'reports/reports_dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  void _onTabTapped(int index) {
    if (index == 0 && _currentIndex != 0) {
      _homeKey.currentState?.reloadHomeScreen();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(key: _homeKey, onNavigateTab: _onTabTapped),
      const InventoryScreen(),
      const BillsListScreen(),
      const ReportsDashboardScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1.0),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          backgroundColor: AppColors.surface,
          elevation: 0,
          indicatorColor: AppColors.primaryContainer,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.home_filled, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
              label: 'Inventory',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
              label: 'Bills',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}
