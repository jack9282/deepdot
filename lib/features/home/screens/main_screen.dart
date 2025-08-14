import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../common/theme/app_theme.dart';
import 'home_screen.dart';
import '../../taking/screens/taking_list_screen.dart';
import '../../routine/screens/routine_screen.dart';
import '../../settings/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final Widget? child;
  
  const MainScreen({super.key, this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const TakingListScreen(),
    const RoutineScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setCurrentIndexFromPath();
  }

  void _setCurrentIndexFromPath() {
    final location = GoRouterState.of(context).uri.path;
    int newIndex = 0;
    
    switch (location) {
      case '/home':
        newIndex = 0;
        break;
      case '/taking-list':
        newIndex = 1;
        break;
      case '/routine':
        newIndex = 2;
        break;
      case '/settings':
        newIndex = 3;
        break;
      default:
        newIndex = 0;
    }
    
    if (_currentIndex != newIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: SafeArea(
        top: false,
        bottom: true,
        child: widget.child ?? IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: Container(
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: 'assets/svg/home.svg',
                  label: '홈',
                ),
                _buildNavItem(
                  index: 1,
                  icon: 'assets/svg/tacking.svg',
                  label: '복용',
                ),
                _buildNavItem(
                  index: 2,
                  icon: 'assets/svg/routine.svg',
                  label: '루틴',
                ),
                _buildNavItem(
                  index: 3,
                  icon: 'assets/svg/setting.svg',
                  label: '설정',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/taking-list');
            break;
          case 2:
            context.go('/routine');
            break;
          case 3:
            context.go('/settings');
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            icon,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontFamily: 'Pretendard',
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}