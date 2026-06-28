import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart'; // <--- الألوان الرسمية

class StudentGradesTab extends StatefulWidget {
  const StudentGradesTab({super.key});

  @override
  State<StudentGradesTab> createState() => _StudentGradesTabState();
}

class _StudentGradesTabState extends State<StudentGradesTab> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _grades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadGrades());
  }

  Future<void> _loadGrades() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getGrades(userId);
      if (mounted) setState(() => _grades = data);
    } catch (e) {
      if (mounted) _showSnackBar('خطأ في جلب كشف العلامات', isError: true);
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
      ),
    );
  }

  double _calcCumulativeGPA() {
    if (_grades.isEmpty) return 0.0;
    double sum = 0;
    for (var g in _grades) {
      final val = double.tryParse(g['grade']?.toString() ?? '0') ?? 0;
      final max = double.tryParse(g['max_grade']?.toString() ?? '100') ?? 100;
      if (max > 0) sum += (val / max) * 100;
    }
    return sum / _grades.length;
  }

  double _calcSemesterGPA(List<Map<String, dynamic>> semGrades) {
    if (semGrades.isEmpty) return 0.0;
    double sum = 0;
    for (var g in semGrades) {
      final val = double.tryParse(g['grade']?.toString() ?? '0') ?? 0;
      final max = double.tryParse(g['max_grade']?.toString() ?? '100') ?? 100;
      if (max > 0) sum += (val / max) * 100;
    }
    return sum / semGrades.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_grades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text('لم يتم رصد أي علامات في سجلك بعد', style: TextStyle(color: mutedColor, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    final semesters = <String, List<Map<String, dynamic>>>{};
    for (var g in _grades) {
      final sem = g['semester'] ?? 'فصل غير محدد';
      semesters.putIfAbsent(sem, () => []).add(g);
    }

    final cumulative = _calcCumulativeGPA();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadGrades,
        child: CustomScrollView(
          slivers: [
            // --- 1. Cumulative Top Banner ---
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15)),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.05), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('المعدّل التراكمي العام', style: TextStyle(fontSize: 12, color: AppColors.lightTextMuted, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(cumulative.toStringAsFixed(1), style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, fontFamily: 'Roboto', color: textColor)),
                            const Text('%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 32),
                    )
                  ],
                ),
              ),
            ),

            // --- 2. Semesters List ---
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final semKey = semesters.keys.elementAt(index);
                    final semList = semesters[semKey]!;
                    final semAvg = _calcSemesterGPA(semList);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Semester Header Bar
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(width: 8),
                                  Text(semKey, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF222F4A) : Colors.grey.shade200)),
                                child: Text('المعدل الفصلي: ${semAvg.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'Roboto', color: mutedColor)),
                              )
                            ],
                          ),
                        ),

                        // كروت المواد بداخل هذا الفصل
                        ...semList.map((grade) => _buildSubjectGradeCard(grade, isDark)).toList(),
                      ],
                    );
                  },
                  childCount: semesters.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)), 
          ],
        ),
      ),
    );
  }

  // --- كرت المادة بالهندسة السورية (معقم للدارك مود) ---
  Widget _buildSubjectGradeCard(Map<String, dynamic> grade, bool isDark) {
    final subject = grade['subject'] ?? 'مادة غير مسماة';
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final innerBg = isDark ? Colors.white10 : const Color(0xFFF8FAFC);
    
    final totalMark = double.tryParse(grade['grade']?.toString() ?? '0') ?? 0;
    final maxMark = double.tryParse(grade['max_grade']?.toString() ?? '100') ?? 100;
    
    final pracMark = double.tryParse(grade['practical_mark']?.toString() ?? '');
    final pracMax = double.tryParse(grade['practical_max']?.toString() ?? '30') ?? 30;
    
    final theoMark = double.tryParse(grade['theoretical_mark']?.toString() ?? '');
    final theoMax = double.tryParse(grade['theoretical_max']?.toString() ?? '70') ?? (maxMark - pracMax);

    final passingMin = double.tryParse(grade['passing_min']?.toString() ?? '60') ?? 60.0;

    final isPassed = totalMark >= passingMin;
    final ratio = maxMark > 0 ? (totalMark / maxMark) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF222F4A) : (isPassed ? Colors.grey.shade100 : Colors.red.shade100), width: isPassed ? 1 : 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: isPassed ? const Color(0xFF10B981) : AppColors.danger, width: 4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Top Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(subject, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: isPassed ? const Color(0xFF10B981).withValues(alpha: 0.15) : AppColors.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isPassed ? Icons.verified_rounded : Icons.dangerous_rounded, size: 12, color: isPassed ? const Color(0xFF10B981) : AppColors.danger),
                        const SizedBox(width: 4),
                        Text(
                          isPassed ? 'مُجتاز' : 'إعادة',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPassed ? const Color(0xFF10B981) : AppColors.danger),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),

              // --- 2. Middle Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المطلوب للنجاح: ${passingMin.toInt()}', style: TextStyle(fontSize: 10, color: mutedColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        isPassed ? 'الوضع الأكاديمي سليم' : 'تحتاج إلى ملاحقة',
                        style: TextStyle(fontSize: 11, color: isPassed ? const Color(0xFF10B981) : AppColors.danger, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        totalMark == totalMark.toInt() ? totalMark.toInt().toString() : totalMark.toStringAsFixed(1),
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Roboto', color: isPassed ? textColor : AppColors.danger),
                      ),
                      Text('/${maxMark.toInt()}', style: TextStyle(fontSize: 13, color: mutedColor, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
              
              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15))),

              // --- 3. Bottom Row: Breakdown Pills ---
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: innerBg, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.biotech_rounded, size: 13, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              pracMark != null ? 'عملي: ${pracMark.toInt()}/${pracMax.toInt()}' : 'عملي: لم يُرصد',
                              style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: theoMark != null ? innerBg : const Color(0xFFF59E0B).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Icon(theoMark != null ? Icons.quiz_rounded : Icons.hourglass_empty_rounded, size: 13, color: theoMark != null ? const Color(0xFF2563EB) : const Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              theoMark != null ? 'نظري: ${theoMark.toInt()}/${theoMax.toInt()}' : 'نظري: بانتظار الفحص',
                              style: TextStyle(fontSize: 11, color: theoMark != null ? textColor : const Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  color: isPassed ? const Color(0xFF10B981) : AppColors.danger,
                  minHeight: 5,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}