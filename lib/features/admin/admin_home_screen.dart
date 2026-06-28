import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/screens/login_screen.dart';
import '../../core/theme/app_colors.dart'; // <--- استوردنا الألوان السيادية

// التبويبات السبعة
import 'dashboard/dashboard_tab.dart';
import 'students/students_tab.dart';
import 'staff/staff_tab.dart';
import 'announcements/announcements_tab.dart';
import 'grades/grades_tab.dart';
import 'schedules/schedules_tab.dart';
import 'requests/requests_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboardTab(),
    AdminStudentsTab(),
    AdminStaffTab(),
    AdminAnnouncementsTab(),
    AdminGradesTab(),
    AdminSchedulesTab(),
    AdminRequestsTab(),
  ];

  // --- دايالوغ تأكيد الخروج (مجهّز للدارك واللايت معاً) ---
  Future<void> _confirmLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? const Color(0xFF222F4A) : Colors.transparent),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 32),
              ),
              const SizedBox(height: 16),
              Text('تسجيل الخروج؟', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text(
                'هل أنت متأكد من رغبتك في مغادرة لوحة تحكم الإدارة؟',
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedColor, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                        padding: const EdgeInsets.symmetric(vertical: 12)
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('بقاء', style: TextStyle(color: mutedColor, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('خروج', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text('الإدارة العامة', style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: isDark ? AppColors.danger.withValues(alpha: 0.15) : Colors.red.shade50, 
                foregroundColor: AppColors.danger
              ),
              icon: const Icon(Icons.power_settings_new_rounded, size: 18),
              onPressed: _confirmLogout,
              tooltip: 'تسجيل الخروج',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.withValues(alpha: 0.15), height: 1),
        ),
      ),

      // --- الذاكرة الفولاذية ---
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // --- شريط M3 Navigation Bar مجهّز ليلاً ونهاراً ---
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
        elevation: 16,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded, color: AppColors.primary), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded, color: AppColors.primary), label: 'الطلاب'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school_rounded, color: AppColors.primary), label: 'الكادر'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign_rounded, color: AppColors.primary), label: 'الإعلان'),
          NavigationDestination(icon: Icon(Icons.military_tech_outlined), selectedIcon: Icon(Icons.military_tech_rounded, color: AppColors.primary), label: 'العلامات'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today_rounded, color: AppColors.primary), label: 'الجدول'),
          NavigationDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox_rounded, color: AppColors.primary), label: 'الطلبات'),
        ],
      ),
    );
  }
}