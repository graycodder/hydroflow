import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF2962FF),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return;
        
        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/stock');
            break;
          case 2:
            context.go('/bottles');
            break;
          case 3:
            context.go('/customers');
            break;
          case 4:
             context.go('/delivery');
            break;
          case 5:
             context.go('/reports');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Stock',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.water_drop_outlined),
          activeIcon: Icon(Icons.water_drop),
          label: 'Bottles',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Customers',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          activeIcon: Icon(Icons.local_shipping),
          label: 'Delivery',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          activeIcon: Icon(Icons.description),
          label: 'Reports',
        ),
      ],
    );
  }
}
