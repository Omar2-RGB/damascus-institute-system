import 'package:flutter/material.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';

class StudentSchedulesTab extends StatefulWidget {
  const StudentSchedulesTab({super.key});

  @override
  State<StudentSchedulesTab> createState() => _StudentSchedulesTabState();
}

class _StudentSchedulesTabState extends State<StudentSchedulesTab> {
  final SupabaseService _supabaseService = SupabaseService();
  final List<String> _weekDays = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];

  UserModel? _studentProfile;
  List<Map<String, dynamic>> _schedule = [];
  String _selectedSemester = 'الفصل الأول';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentDataAndSchedule();
  }

  // تحويل رقم السنة من البروفايل إلى نص ليطابق فلاتر الجدول
  String _getYearString(int? year) {
    switch (year) {
      case 1: return 'السنة الأولى';
      case 2: return 'السنة الثانية';
      case 3: return 'السنة الثالثة';
      case 4: return 'السنة الرابعة';
      case 5: return 'السنة الخامسة';
      default: return 'السنة الأولى';
    }
  }

  Future<void> _loadStudentDataAndSchedule() async {
    setState(() => _isLoading = true);
    try {
      // 1. جلب بيانات الطالب الحالي
      final uid = _supabaseService.getCurrentUserId();
      if (uid != null) {
        _studentProfile = await _supabaseService.getProfile(uid);
        
        // 2. جلب جدوله تلقائياً إذا كان تخصصه وسنته مسجلين
        if (_studentProfile?.department != null && _studentProfile?.year != null) {
          final dept = _studentProfile!.department!;
          final yearStr = _getYearString(_studentProfile!.year);
          
          final data = await _supabaseService.getScheduleByFilters(dept, yearStr, _selectedSemester);
          if (mounted) setState(() => _schedule = data);
        }
      }
    } catch (e) {
      debugPrint('خطأ في تحميل الجدول: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getSortedLecturesForDay(String day) {
    final list = _schedule.where((e) => (e['day_of_week'] ?? '').trim() == day).toList();
    list.sort((a, b) => (a['start_time'] ?? '').compareTo(b['start_time'] ?? ''));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final hasCompleteProfile = _studentProfile?.department != null && _studentProfile?.year != null;

    return Scaffold(
      body: Column(
        children: [
          // --- 1. رأس الشاشة (معلومات الطالب + تبديل الفصل) ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface, 
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))], 
              border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الجدول الدراسي الثابت', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                        if (hasCompleteProfile)
                          Text('${_studentProfile!.department} • ${_getYearString(_studentProfile!.year)}', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // زر تبديل الفصل (بديل الـ Dropdown الأنيق)
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131C2E) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ['الفصل الأول', 'الفصل الثاني'].map((sem) {
                      final isSelected = _selectedSemester == sem;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!isSelected) {
                              setState(() => _selectedSemester = sem);
                              _loadStudentDataAndSchedule();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(sem, style: TextStyle(
                              color: isSelected ? Colors.white : mutedColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            )),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // --- 2. محتوى الجدول الأسبوعي ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : !hasCompleteProfile
                    ? _buildPlaceholder(Icons.warning_amber_rounded, 'بيانات تخصصك الأكاديمي غير مكتملة.\nيرجى مراجعة الإدارة لتحديث بياناتك.', isDark)
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadStudentDataAndSchedule,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _weekDays.length,
                          itemBuilder: (context, index) {
                            final dayName = _weekDays[index];
                            final dayLectures = _getSortedLecturesForDay(dayName);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(bottom: 10, top: index > 0 ? 14 : 0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(width: 4, height: 16, decoration: BoxDecoration(color: dayLectures.isEmpty ? Colors.grey.withValues(alpha: 0.4) : AppColors.primary, borderRadius: BorderRadius.circular(2))),
                                          const SizedBox(width: 8),
                                          Text(dayName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: dayLectures.isEmpty ? mutedColor : textColor)),
                                        ],
                                      ),
                                      Text(
                                        dayLectures.isEmpty ? 'يوم حر' : '${dayLectures.length} محاضرات', 
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dayLectures.isEmpty ? Colors.grey.withValues(alpha: 0.4) : AppColors.primary),
                                      )
                                    ],
                                  ),
                                ),

                                if (dayLectures.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF222F4A) : Colors.grey.shade200)),
                                    child: const Center(child: Text('🏖️ لا توجد محاضرات مبرمجة في هذا اليوم', style: TextStyle(color: AppColors.lightTextMuted, fontSize: 12, fontWeight: FontWeight.w600))),
                                  )
                                else
                                  ...dayLectures.map((lec) => _buildReadOnlyLectureCard(lec, isDark, textColor)),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // كرت القراءة فقط (للطالب)
  Widget _buildReadOnlyLectureCard(Map<String, dynamic> lec, bool isDark, Color textColor) {
    final timeStr = '${lec['start_time'] ?? ''} - ${lec['end_time'] ?? ''}';
    final subject = lec['subject'] ?? 'بدون مادة';
    final room = lec['room'] ?? 'قاعة غير محددة';
    final instructor = lec['staff']?['name'] ?? 'غير مدرج';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: isDark ? const Color(0xFF222F4A) : Colors.grey.shade200), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.primary, width: 4))),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(timeStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'Roboto', color: AppColors.primary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text('📍 $room', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(subject, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.record_voice_over_rounded, size: 13, color: AppColors.lightTextMuted),
                  const SizedBox(width: 4),
                  Text(instructor, style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted, fontWeight: FontWeight.w600)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon, String text, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 14, height: 1.6, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}