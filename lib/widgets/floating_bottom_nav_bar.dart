import 'package:flutter/material.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/order/assigned_orders_screen.dart';
import '../screens/profile/settings_screen.dart';

class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const FloatingBottomNavBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const DashboardScreen();
        break;
      case 1:
        nextScreen = const AssignedOrdersScreen();
        break;
      case 2:
        nextScreen = const SettingsScreen();
        break;
      default:
        return;
    }

    // Use pushReplacement for main tabs to avoid huge navigation stack
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(context, 0, Icons.home_filled),
          _buildNavItem(context, 1, Icons.shopping_cart_rounded),
          _buildNavItem(context, 2, Icons.person_outline),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon) {
    bool isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF4D00) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : const Color(0xFFBBBBBB),
          size: 26,
        ),
      ),
    );
  }
}
