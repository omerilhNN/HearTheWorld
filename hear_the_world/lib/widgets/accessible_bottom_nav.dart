import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';
import '../main.dart';

class AccessibleBottomNav extends StatelessWidget {
  final Function(int) onTabChanged;

  const AccessibleBottomNav({super.key, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    final navigationController = Provider.of<NavigationController>(context);
    final currentIndex = navigationController.currentIndex;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          navigationController.changeIndex(index);
          onTabChanged(index);

          // Provide audio feedback based on selected tab
          String screenName = '';
          switch (index) {            case 0:
              screenName = 'Home';
              break;
            case 1:
              screenName = 'History';
              break;
            case 2:
              screenName = 'Settings';
              break;
            case 3:
              screenName = 'Forum';
              break;
          }

          AccessibilityService().speak('$screenName screen');
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedFontSize: 14,
        unselectedFontSize: 14,
        iconSize: 28,
        type: BottomNavigationBarType.fixed,        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            tooltip: 'Go to home screen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
            tooltip: 'Go to history screen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
            tooltip: 'Go to settings screen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Forum',
            tooltip: 'Go to memories forum',
          ),
        ],
      ),
    );
  }
}
