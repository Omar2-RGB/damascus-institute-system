import 'package:flutter/material.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart'; // <--- استوردنا مخزن ألوان المعهد

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _loading = true;
  int _studentsCount = 0;
  int _staffCount = 0;
  int _announcementsCount = 0;
  int _groupsCount = 0;
  int _pendingRequests = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final stats = await _supabaseService.getDashboardCounts();
      final groups = await _supabaseService.getAllGroups();
      if (mounted) {
        setState(() {
          _studentsCount = stats['students'] ?? 0;
          _staffCount = stats['staff'] ?? 0;
          _announcementsCount = stats['announcements'] ?? 0;
          _pendingRequests = stats['pendingRequests'] ?? 0;
          _groupsCount = groups.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الإحصائيات: $e', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Scaffold(
      // --- تركنا الخلفية سادة لتشفط لون الـ AppTheme تلقائياً ---
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Text('نظرة عامة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 4),
              Text('إحصائيات المعهد المحدّثة لحظياً', style: TextStyle(fontSize: 13, color: mutedColor)),
              const SizedBox(height: 20),

              // --- 1. Hero Action Banner (الطلبات المعلقة) ---
              _buildPendingHeroCard(isDark),

              const SizedBox(height: 24),
              Text('المؤشرات الأكاديمية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 14),

              // --- 2. Balanced 2x2 Grid ---
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.15, 
                children: [
                  _buildModernStatCard(
                    title: 'الطلاب',
                    count: _studentsCount,
                    icon: Icons.people_alt_rounded,
                    color: AppColors.primary, 
                    bgTint: isDark ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
                    isDark: isDark,
                  ),
                  _buildModernStatCard(
                    title: 'الأساتذة',
                    count: _staffCount,
                    icon: Icons.school_rounded,
                    color: AppColors.success, 
                    bgTint: isDark ? AppColors.success.withValues(alpha: 0.15) : const Color(0xFFECFDF5),
                    isDark: isDark,
                  ),
                  _buildModernStatCard(
                    title: 'المجموعات',
                    count: _groupsCount,
                    icon: Icons.layers_rounded,
                    color: const Color(0xFF7C3AED), 
                    bgTint: isDark ? const Color(0xFF7C3AED).withValues(alpha: 0.15) : const Color(0xFFF5F3FF),
                    isDark: isDark,
                  ),
                  _buildModernStatCard(
                    title: 'الإعلانات',
                    count: _announcementsCount,
                    icon: Icons.campaign_rounded,
                    color: AppColors.warning, 
                    bgTint: isDark ? AppColors.warning.withValues(alpha: 0.15) : const Color(0xFFFEF3C7),
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // البانر الذكي للطلبات (مجهز للدارك واللايت معاً)
  Widget _buildPendingHeroCard(bool isDark) {
    final hasPending = _pendingRequests > 0;
    final mainColor = hasPending ? AppColors.danger : const Color(0xFF0D9488); 
    final lightTint = hasPending 
        ? (isDark ? AppColors.danger.withValues(alpha: 0.15) : Colors.red.shade50) 
        : (isDark ? const Color(0xFF0D9488).withValues(alpha: 0.15) : const Color(0xFFF0FDFA));
        
    final iconData = hasPending ? Icons.notification_important_rounded : Icons.check_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasPending ? mainColor.withValues(alpha: 0.4) : Colors.teal.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: mainColor.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: lightTint, shape: BoxShape.circle),
            child: Icon(iconData, color: mainColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPending ? 'تنبيه إجراءات' : 'الوضع مستقر',
                  style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPending ? '$_pendingRequests طلبات بانتظار الاعتماد' : 'لا توجد طلبات معلقة حالياً',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: hasPending ? (isDark ? Colors.redAccent : Colors.red.shade900) : (isDark ? Colors.white : const Color(0xFF1E293B))),
                ),
              ],
            ),
          ),
          if (hasPending)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                // TODO: Navigate to pending requests tab
              },
              child: const Text('عالجها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            )
        ],
      ),
    );
  }

  // الكرت الإحصائي المودرن (Cinematic Card)
  Widget _buildModernStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgTint,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF222F4A) : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bgTint, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              Icon(Icons.auto_graph_rounded, size: 18, color: isDark ? Colors.white12 : Colors.grey.shade200),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.w900, 
                  color: isDark ? Colors.white : const Color(0xFF1E293B), 
                  fontFamily: 'Roboto' 
                ),
              ),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(fontSize: 13, color: AppColors.lightTextMuted, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}