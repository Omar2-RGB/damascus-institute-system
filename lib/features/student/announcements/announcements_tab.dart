import 'package:flutter/material.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart'; // <--- استوردنا مخزن ألوان المعهد

class StudentAnnouncementsTab extends StatefulWidget {
  const StudentAnnouncementsTab({super.key});

  @override
  State<StudentAnnouncementsTab> createState() => _StudentAnnouncementsTabState();
}

class _StudentAnnouncementsTabState extends State<StudentAnnouncementsTab> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getAnnouncements();
      if (mounted) setState(() => _announcements = data);
    } catch (e) {
      if (mounted) _showSnackBar('خطأ في تحميل الإعلانات', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
        backgroundColor: isError ? AppColors.danger : (isDark ? Colors.white : const Color(0xFF0F172A)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    
    if (_announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text('لا توجد إعلانات حالياً', style: TextStyle(color: mutedColor, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadAnnouncements,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: _announcements.length,
          itemBuilder: (context, index) {
            final a = _announcements[index];
            final title = a['title'] ?? '';
            final body = a['body'] ?? '';
            final date = a['created_at']?.toString().substring(0, 10) ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131C2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF222F4A) : Colors.grey.shade100),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  collapsedIconColor: isDark ? Colors.white54 : AppColors.lightTextMuted,
                  iconColor: AppColors.primary,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.campaign_rounded, color: AppColors.primary),
                  ),
                  title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(date, style: TextStyle(fontSize: 11, color: mutedColor, fontFamily: 'Roboto')),
                  ),
                  children: [
                    Divider(color: Colors.grey.withValues(alpha: 0.15), indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Text(
                        body, 
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF1E293B), height: 1.5)
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}