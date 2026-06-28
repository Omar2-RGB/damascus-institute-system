import 'package:flutter/material.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../data/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';

class StudentAttendanceView extends StatefulWidget {
  final UserModel student;
  const StudentAttendanceView({super.key, required this.student});

  @override
  State<StudentAttendanceView> createState() => _StudentAttendanceViewState();
}

class _StudentAttendanceViewState extends State<StudentAttendanceView> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _attendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getAttendance(widget.student.id);
      if (mounted) setState(() => _attendance = data);
    } catch (_) {
      // تجاهل صامت كي لا نزعج الموظف
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ({String label, Color color, Color bgTint, IconData icon}) _getStatusMeta(String? status) {
    switch (status) {
      case 'present': return (label: 'حاضر', color: AppColors.success, bgTint: AppColors.success.withValues(alpha: 0.15), icon: Icons.check_circle_rounded);
      case 'absent':  return (label: 'غائب', color: AppColors.danger, bgTint: AppColors.danger.withValues(alpha: 0.15), icon: Icons.cancel_rounded);
      case 'late':    return (label: 'متأخر', color: AppColors.warning, bgTint: AppColors.warning.withValues(alpha: 0.15), icon: Icons.schedule_rounded);
      default:        return (label: 'غير مرصود', color: Colors.grey, bgTint: Colors.grey.withValues(alpha: 0.1), icon: Icons.help_outline_rounded);
    }
  }

  double _calculateRate() {
    if (_attendance.isEmpty) return 100.0;
    final p = _attendance.where((e) => e['status'] == 'present').length;
    final l = _attendance.where((e) => e['status'] == 'late').length;
    return ((p + (l * 0.5)) / _attendance.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rate = _calculateRate();
    final isDanger = rate < 75.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('سجل مواظبة: ${widget.student.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _attendance.isEmpty
              ? Center(child: Text('لا توجد سجلات حضور أو غياب مرصودة لهذا الطالب', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)))
              : Column(
                  children: [
                    // --- Bento Box Stat ---
                    Container(
                      margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDanger ? AppColors.danger : (isDark ? const Color(0xFF222F4A) : Colors.grey.shade200)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('نسبة الحضور التراكمية', style: TextStyle(fontSize: 12, color: AppColors.lightTextMuted, fontWeight: FontWeight.bold)),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(rate.toStringAsFixed(0), style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, fontFamily: 'Roboto', color: isDanger ? AppColors.danger : (isDark ? Colors.white : Colors.black))),
                                  const Text('%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ],
                              ),
                              if (isDanger)
                                const Text('⚠️ إنذار بالحرمان (تحت 75%)', style: TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.bold))
                            ],
                          ),
                          Icon(isDanger ? Icons.warning_rounded : Icons.verified_rounded, color: isDanger ? AppColors.danger : AppColors.success, size: 42)
                        ],
                      ),
                    ),

                    const Text('تفصيل الجلسات', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // --- History List ---
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: _attendance.length,
                        itemBuilder: (context, index) {
                          final a = _attendance[index];
                          final subj = a['schedules']?['subject'] ?? 'جلسة دراسية';
                          final dateStr = a['date']?.toString() ?? '';
                          final meta = _getStatusMeta(a['status']);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: meta.bgTint, child: Icon(meta.icon, color: meta.color, size: 18)),
                              title: Text(subj, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.lightTextMuted)),
                              trailing: Text(meta.label, style: TextStyle(color: meta.color, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
    );
  }
}