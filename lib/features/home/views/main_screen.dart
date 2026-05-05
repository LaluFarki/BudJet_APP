import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/views/profile_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // ── FAB Animation ──
  bool _isFabOpen = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _rotateAnim = Tween<double>(begin: 0, end: 0.375).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<Widget> get _pages => [
        HomeScreen(onProfileTap: () => _onNavTapped(1)),
        const ProfileScreen(),
      ];

  void _onNavTapped(int index) {
    if (_isFabOpen) _closeFab();
    setState(() => _currentIndex = index);
  }

  void _toggleFab() {
    setState(() => _isFabOpen = !_isFabOpen);
    if (_isFabOpen) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _closeFab() {
    setState(() => _isFabOpen = false);
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tap di luar FAB → tutup
      onTap: _isFabOpen ? _closeFab : null,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Stack(
          children: [
            // ── Halaman Utama ──
            IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),

            // ── Overlay gelap saat FAB terbuka ──
            if (_isFabOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeFab,
                  child: AnimatedOpacity(
                    opacity: _isFabOpen ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                  ),
                ),
              ),

            // ── Expanded Mini FABs (Center Aligned) ──
            Positioned(
              bottom: 50, // Distance from the main docked FAB
              left: 0,
              right: 0,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Voice Note Option
                    _buildActionItem(
                      label: 'Voice Note',
                      icon: Icons.graphic_eq_rounded,
                      onTap: () {
                        _closeFab();
                        Get.snackbar(
                          'Voice Note',
                          'Fitur voice note segera hadir!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(0xFFDCE775),
                          colorText: AppColors.textDark,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 12,
                        );
                      },
                    ),
                    const SizedBox(width: 40), // Spacing between the buttons
                    // Manual Option
                    _buildActionItem(
                      label: 'Manual',
                      icon: Icons.edit_rounded,
                      onTap: () {
                        _closeFab();
                        Get.toNamed('/add-tx');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── FAB Utama (tombol +) ──
        floatingActionButton: RotationTransition(
          turns: _rotateAnim,
          child: FloatingActionButton(
            elevation: 4,
            backgroundColor: const Color(0xFFDCE775),
            shape: const CircleBorder(),
            onPressed: _toggleFab,
            child: const Icon(Icons.add, color: AppColors.textDark, size: 28),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // ── Bottom Navigation Bar ──
        bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 32,
                  icon: Icon(
                    Icons.home_rounded,
                    color: _currentIndex == 0
                        ? AppColors.textDark
                        : AppColors.textGrey,
                  ),
                  onPressed: () => _onNavTapped(0),
                ),
                const SizedBox(width: 48), // Space for the docked FAB
                IconButton(
                  iconSize: 32,
                  icon: Icon(
                    Icons.person_rounded,
                    color: _currentIndex == 1
                        ? AppColors.textDark
                        : AppColors.textGrey,
                  ),
                  onPressed: () => _onNavTapped(1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper: Combines Mini FAB and Label into a clean Column ──
  Widget _buildActionItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE775),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDCE775).withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.textDark, size: 24),
          ),
        ),
        const SizedBox(height: 8), // Gap between button and label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.textDark.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}