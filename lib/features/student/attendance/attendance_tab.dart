import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart'; // <--- استوردنا الألوان السيادية

class StudentAttendanceTab extends StatefulWidget {
  const StudentAttendanceTab({super.key});

  @override
  State<StudentAttendanceTab> createState() => _StudentAttendanceTabState();
}

class _StudentAttendanceTabState extends State<StudentAttendanceTab> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _attendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // الحل الأمثل للـ Provider بدون تكرار
    Future.microtask(() => _loadAttendance());
  }

  Future<void> _loadAttendance() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getAttendance(userId);
      if (mounted) setState(() => _attendance = data);
    } catch (e) {
      if (mounted) _showSnackBar('خطأ في جلب سجل الحضور', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
        backgroundColor: isError ? AppColors.danger : (isDark ? Colors.white : const Color(0xFF0F172A)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      )
    );
  }

  // تم دمج bgTint لتعمل بذكاء عبر withValues(alpha: 0.15)
  ({String label, Color color, IconData icon}) _getStatusMeta(String? status) {
    switch (status) {
      case 'present': return (label: 'حاضر', color: const Color(0xFF10B981), icon: Icons.check_circle_rounded); // Emerald Green
      case 'absent': return (label: 'غائب', color: AppColors.danger, icon: Icons.cancel_rounded); // Danger Red
      case 'late': return (label: 'متأخر', color: const Color(0xFFF59E0B), icon: Icons.schedule_rounded); // Amber
      default: return (label: 'غير معروف', color: Colors.grey, icon: Icons.help_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    
    if (_attendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text('لا يوجد سجل حضور مسجل بعد', style: TextStyle(color: mutedColor, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadAttendance,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _attendance.length,
          itemBuilder: (context, index) {
            final a = _attendance[index];
            final meta = _getStatusMeta(a['status']);
            final subject = a['schedules']?['subject'] ?? 'مادة غير معروفة';
            final date = a['date']?.toString().substring(0, 10) ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131C2E) : Colors.white, 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: isDark ? const Color(0xFF222F4A) : Colors.grey.shade100),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: meta.color.withValues(alpha: 0.15), // شفافية ذكية
                    shape: BoxShape.circle
                  ),
                  child: Icon(meta.icon, color: meta.color, size: 20),
                ),
                title: Text(subject, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('$date • ${meta.label}', style: TextStyle(fontSize: 12, color: meta.color, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}