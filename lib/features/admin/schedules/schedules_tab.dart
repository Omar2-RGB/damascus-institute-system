import 'package:flutter/material.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';

class AdminSchedulesTab extends StatefulWidget {
  const AdminSchedulesTab({super.key});

  @override
  State<AdminSchedulesTab> createState() => _AdminSchedulesTabState();
}

class _AdminSchedulesTabState extends State<AdminSchedulesTab> {
  final SupabaseService _supabaseService = SupabaseService();

  final List<String> _departments = ['هندسة برمجيات', 'شبكات حاسوب', 'تكنولوجيا حواسيب', 'ذكاء اصطناعي'];
  final List<String> _years = ['السنة الأولى', 'السنة الثانية'];
  final List<String> _semesters = ['الفصل الأول', 'الفصل الثاني'];
  final List<String> _weekDays = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];

  String? _selectedDept;
  String? _selectedYear;
  String? _selectedSemester;

  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _schedule = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final staff = await _supabaseService.getAllStaff();
      if (mounted) setState(() => _staffList = staff);
    } catch (e) {
      debugPrint('خطأ في تحميل الكادر: $e');
    }
  }

  Future<void> _loadSchedule() async {
    if (_selectedDept == null || _selectedYear == null || _selectedSemester == null) return;
    
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getScheduleByFilters(_selectedDept!, _selectedYear!, _selectedSemester!);
      if (mounted) setState(() => _schedule = data);
    } catch (e) {
      if (mounted) _showSnackBar('خطأ في تحميل الجدول: $e', isError: true);
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
      ),
    );
  }

  List<Map<String, dynamic>> _getSortedLecturesForDay(String day) {
    final list = _schedule.where((e) => (e['day_of_week'] ?? '').trim() == day).toList();
    list.sort((a, b) => (a['start_time'] ?? '').compareTo(b['start_time'] ?? ''));
    return list;
  }

  Future<void> _confirmAndDeleteEntry(String id, String subject) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_rounded, color: AppColors.danger, size: 48),
              const SizedBox(height: 16),
              Text('إلغاء المحاضرة؟', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text('هل أنت متأكد من حذف محاضرة "$subject" من الجدول؟', textAlign: TextAlign.center, style: TextStyle(color: mutedColor, fontSize: 14)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(context, false), child: Text('تراجع', style: TextStyle(color: mutedColor, fontWeight: FontWeight.bold)))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)))),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _supabaseService.deleteScheduleEntry(id);
        await _loadSchedule();
        if (mounted) _showSnackBar('تم حذف المحاضرة بنجاح');
      } catch (e) {
        if (mounted) _showSnackBar('خطأ في الحذف: $e', isError: true);
      }
    }
  }

  void _openScheduleEntryModal([Map<String, dynamic>? existingEntry]) {
    if (_selectedDept == null || _selectedYear == null || _selectedSemester == null) return;

    final isEditing = existingEntry != null;

    String selectedDay = isEditing ? (existingEntry['day_of_week'] ?? 'الأحد') : 'الأحد';
    final startController = TextEditingController(text: isEditing ? existingEntry['start_time'] : '09:00');
    final endController = TextEditingController(text: isEditing ? existingEntry['end_time'] : '10:30');
    final subjectController = TextEditingController(text: isEditing ? existingEntry['subject'] : '');
    final roomController = TextEditingController(text: isEditing ? existingEntry['room'] : '');
    String? selectedStaffId = isEditing ? (existingEntry['staff_id'] ?? existingEntry['instructor_id']) : null;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 20, right: 20, top: 16),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text(isEditing ? 'تعديل موعد المحاضرة' : 'إضافة محاضرة للجدول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 6),
                  Text('$_selectedDept • $_selectedYear • $_selectedSemester', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 18),

                  _buildCustomTextField(controller: subjectController, label: 'اسم المادة *', icon: Icons.menu_book_rounded, isDark: isDark),
                  const SizedBox(height: 12),

                  _buildModernDropdown<String>(
                    hint: 'اليوم *', icon: Icons.today_rounded, isDark: isDark,
                    value: _weekDays.contains(selectedDay) ? selectedDay : 'الأحد',
                    items: _weekDays,
                    onChanged: (val) => setModalState(() => selectedDay = val!),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: _buildCustomTextField(controller: startController, label: 'من (HH:MM) *', icon: Icons.access_time_rounded, isDark: isDark)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCustomTextField(controller: endController, label: 'إلى (HH:MM) *', icon: Icons.timelapse_rounded, isDark: isDark)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(color: isDark ? const Color(0xFF131C2E) : Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedStaffId,
                              isExpanded: true,
                              dropdownColor: isDark ? const Color(0xFF131C2E) : Colors.white,
                              hint: Row(children: [const Icon(Icons.person_4_rounded, color: AppColors.primary, size: 18), const SizedBox(width: 8), Text('الأستاذ المحاضر', style: TextStyle(color: AppColors.lightTextMuted, fontSize: 12))]),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                              style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w600),
                              items: _staffList.map((s) => DropdownMenuItem<String>(value: s['id']?.toString(), child: Text(s['name'] ?? 'أستاذ'))).toList(),
                              onChanged: (val) => setModalState(() => selectedStaffId = val),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(flex: 1, child: _buildCustomTextField(controller: roomController, label: 'القاعة', icon: Icons.meeting_room_rounded, isDark: isDark)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(context);
                        try {
                          if (isEditing) {
                            await _supabaseService.updateScheduleEntry(existingEntry['id'], {
                              'day_of_week': selectedDay,
                              'start_time': startController.text.trim(),
                              'end_time': endController.text.trim(),
                              'subject': subjectController.text.trim(),
                              'room': roomController.text.trim().isEmpty ? null : roomController.text.trim(),
                              'instructor_id': selectedStaffId,
                            });
                            if (mounted) _showSnackBar('تم تعديل موعد المحاضرة');
                          } else {
                            await _supabaseService.addScheduleEntry(
                              department: _selectedDept!,
                              year: _selectedYear!,
                              semester: _selectedSemester!,
                              dayOfWeek: selectedDay,
                              startTime: startController.text.trim(),
                              endTime: endController.text.trim(),
                              subject: subjectController.text.trim(),
                              room: roomController.text.trim().isEmpty ? null : roomController.text.trim(),
                              instructorId: selectedStaffId,
                            );
                            if (mounted) _showSnackBar('تمت إضافة المحاضرة للجدول الثابت');
                          }
                          await _loadSchedule();
                        } catch (e) {
                          if (mounted) _showSnackBar('خطأ: $e', isError: true);
                        }
                      },
                      child: Text(isEditing ? 'حفظ التعديل' : 'تثبيت في الجدول', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomTextField({required TextEditingController controller, required String label, required IconData icon, required bool isDark}) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final fillColor = isDark ? const Color(0xFF131C2E) : Colors.grey.shade100;

    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        filled: true, fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (v) => label.contains('*') && (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    
    final isFiltersComplete = _selectedDept != null && _selectedYear != null && _selectedSemester != null;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface, 
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))], 
              border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تحديد الجدول الدراسي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 12),
                
                _buildModernDropdown<String>(
                  hint: 'اختر التخصص الأكاديمي...', icon: Icons.account_balance_rounded, items: _departments, value: _selectedDept,
                  onChanged: (val) { setState(() => _selectedDept = val); _loadSchedule(); }, isDark: isDark
                ),
                const SizedBox(height: 10),
                
                Row(
                  children: [
                    Expanded(child: _buildModernDropdown<String>(hint: 'السنة...', icon: Icons.school_rounded, items: _years, value: _selectedYear, onChanged: (val) { setState(() => _selectedYear = val); _loadSchedule(); }, isDark: isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildModernDropdown<String>(hint: 'الفصل...', icon: Icons.date_range_rounded, items: _semesters, value: _selectedSemester, onChanged: (val) { setState(() => _selectedSemester = val); _loadSchedule(); }, isDark: isDark)),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: !isFiltersComplete
                ? _buildPlaceholder(Icons.touch_app_rounded, 'قم بتحديد التخصص والسنة والفصل من الأعلى لعرض الجدول الثابت', isDark)
                : _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadSchedule,
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
                                // السطر السحري اللي بيعالج الكراش الأحمر تماماً
                                // ignore: unnecessary_to_list_in_spreads
                                ...dayLectures.map((lec) => _buildLectureCard(lec, isDark, textColor, mutedColor)).toList(),
                            ],
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),

      floatingActionButton: !isFiltersComplete ? null : FloatingActionButton.extended(
        onPressed: () => _openScheduleEntryModal(),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded, size: 20),
        label: const Text('إضافة محاضرة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildModernDropdown<T>({required String hint, required IconData icon, required List<T> items, required T? value, required Function(T?) onChanged, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          dropdownColor: isDark ? const Color(0xFF131C2E) : Colors.white,
          hint: Row(children: [Icon(icon, color: AppColors.primary, size: 18), const SizedBox(width: 8), Text(hint, style: const TextStyle(color: AppColors.lightTextMuted, fontSize: 12))]),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E293B)),
          items: items.map((i) => DropdownMenuItem<T>(value: i, child: Text(i.toString()))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLectureCard(Map<String, dynamic> lec, bool isDark, Color textColor, Color mutedColor) {
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.record_voice_over_rounded, size: 13, color: AppColors.lightTextMuted),
                      const SizedBox(width: 4),
                      Text(instructor, style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    children: [
                      InkWell(onTap: () => _openScheduleEntryModal(lec), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_rounded, size: 16, color: Colors.blue))),
                      const SizedBox(width: 10),
                      InkWell(onTap: () => _confirmAndDeleteEntry(lec['id'] ?? '', subject), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent))),
                    ],
                  )
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
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 13, height: 1.5, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}