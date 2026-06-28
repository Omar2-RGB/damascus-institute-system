import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart'; // <--- استوردنا الألوان السيادية

class StudentDashboardTab extends StatelessWidget {
  final Function(int) onNavigate; 

  const StudentDashboardTab({super.key, required this.onNavigate});

  String _getDynamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الهمّة والنشاط ☀️';
    if (hour < 17) return 'مساء الخيرات 🌤️';
    return 'سهرة دراسية موفقة 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final studentName = user?.name ?? 'طالب المعهد';
    final sId = user?.studentId ?? '---';
    final dept = user?.department ?? 'تخصص عام';
    final year = user?.year?.toString() ?? '1';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC), 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Dynamic Top Bar ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getDynamicGreeting(), style: TextStyle(fontSize: 12, color: mutedColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        studentName.split(' ').take(2).join(' '), // نأخذ أول اسمين فقط للجمالية
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131C2E) : Colors.white, 
                      shape: BoxShape.circle, 
                      border: Border.all(color: isDark ? const Color(0xFF222F4A) : Colors.grey.shade200)
                    ),
                    child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 22),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // --- 2. The Apple Wallet VIP Pass (بطاقة الطالب الرقمية) ---
              _buildDigitalStudentCard(studentName, sId, dept, year, isDark),

              const SizedBox(height: 26),

              // --- 3. Bento Box Section (نظرة سريعة) ---
              Text('الحالة الأكاديمية', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBentoSquare(
                      icon: Icons.verified_user_rounded, 
                      title: 'الوضع الأكاديمي', value: 'مستقر 🟢', 
                      color: const Color(0xFF10B981), // Emerald Green
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoSquare(
                      icon: Icons.event_available_rounded, 
                      title: 'التقويم الجامعي', value: 'الفصل الأول', 
                      color: const Color(0xFFF59E0B), // Amber
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // --- 4. Interactive Command Shortcuts ---
              Text('بوابات الوصول السريع', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 12),

              _buildModernShortcutCard(
                title: 'لوحة الإعلانات والتعاميم',
                subtitle: 'قرارات المعهد، تأجيل المحاضرات، ومواعيد الامتحانات',
                icon: Icons.campaign_rounded,
                iconColor: const Color(0xFFF59E0B), // Amber
                badgeText: 'جديد',
                isDark: isDark,
                onTap: () => onNavigate(1),
              ),
              _buildModernShortcutCard(
                title: 'الجدول الدراسي الأسبوعي',
                subtitle: 'أماكن وتواقيت المحاضرات المخصصة لمجموعتك',
                icon: Icons.calendar_month_rounded,
                iconColor: AppColors.primary,
                isDark: isDark,
                onTap: () => onNavigate(2),
              ),
              _buildModernShortcutCard(
                title: 'سجل الحضور والمواظبة',
                subtitle: 'متابعة عدّاد الغيابات ومؤشر الأمان التراكمي',
                icon: Icons.analytics_rounded,
                iconColor: const Color(0xFF8B5CF6), // Violet
                isDark: isDark,
                onTap: () => onNavigate(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ويدجت الهوية الرقمية الخرافية
  Widget _buildDigitalStudentCard(String name, String id, String dept, String year, bool isDark) {
    return AspectRatio(
      aspectRatio: 1.65, 
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)], // Primary & Accent
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.3), blurRadius: 24, offset: const Offset(0, 10)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: -24, bottom: -24,
              child: Icon(Icons.account_balance_rounded, size: 160, color: Colors.white.withValues(alpha: 0.07)),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.school_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text('جامعة دمشق • فرع درعا', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Icon(Icons.contactless_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('بطاقة طالب رقمية', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: Text('$dept • سنة $year', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: Text('ID: $id', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'Roboto')),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // مربعات البينتو المعقمة للدارك مود
  Widget _buildBentoSquare({required IconData icon, required String title, required String value, required Color color, required bool isDark}) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: isDark ? const Color(0xFF222F4A) : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8), 
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), 
            child: Icon(icon, color: color, size: 18)
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.lightTextMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textColor)),
        ],
      ),
    );
  }

  // كروت الاختصارات التفاعلية
  Widget _buildModernShortcutCard({required String title, required String subtitle, required IconData icon, required Color iconColor, String? badgeText, required bool isDark, required VoidCallback onTap}) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: isDark ? const Color(0xFF222F4A) : Colors.grey.shade100), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 2))]
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12), 
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)), 
                child: Icon(icon, color: iconColor, size: 22)
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                            decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), 
                            child: Text(badgeText, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.danger))
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: mutedColor, height: 1.3)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white24 : Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}