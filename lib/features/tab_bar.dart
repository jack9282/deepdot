import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../common/theme/app_theme.dart';

class CustomTabBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final List<TabItem> tabs;

  const CustomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.tabs,
  });

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: widget.tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            return _buildTabItem(tab, index);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabItem(TabItem tab, int index) {
    final isSelected = widget.currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        widget.onTabChanged(index);
        if (tab.onTap != null) {
          tab.onTap!();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.buttonColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          tab.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class TabItem {
  final String title;
  final VoidCallback? onTap;

  const TabItem({
    required this.title,
    this.onTap,
  });
}

// 복용 관련 탭 바를 위한 전용 위젯
class TakingTabBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;

  const TakingTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  State<TakingTabBar> createState() => _TakingTabBarState();
}

class _TakingTabBarState extends State<TakingTabBar> {
  late List<TabItem> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      TabItem(
        title: '홈',
        onTap: () {
          context.go('/home');
        },
      ),
      TabItem(
        title: '복용',
        onTap: () {
          context.go('/taking-list');
        },
      ),
      TabItem(
        title: '루틴',
        onTap: () {
          context.go('/routine');
        },
      ),
      TabItem(
        title: '설정',
        onTap: () {
          context.go('/settings');
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // 현재 경로에 따라 탭 인덱스 결정
    final currentPath = GoRouterState.of(context).uri.path;
    int currentTabIndex = 0;
    
    switch (currentPath) {
      case '/home':
        currentTabIndex = 0;
        break;
      case '/taking-list':
        currentTabIndex = 1;
        break;
      case '/routine':
        currentTabIndex = 2;
        break;
      case '/settings':
        currentTabIndex = 3;
        break;
      default:
        currentTabIndex = 0;
    }

    return CustomTabBar(
      currentIndex: currentTabIndex,
      onTabChanged: widget.onTabChanged,
      tabs: _tabs,
    );
  }
}
