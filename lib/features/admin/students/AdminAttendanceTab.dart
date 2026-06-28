import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../data/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';

// ============================================================================
// 1. شاشة مستكشف التفقّد (مع فلتر السنة والقسم + الدارك مود الصافي)
// ============================================================================
class AdminAttendanceTab extends StatefulWidget {
  const AdminAttendanceTab({super.key});

  @override
  State<AdminAttendanceTab> createState() => _AdminAttendanceTabState();
}

class _AdminAttendanceTabState extends State<AdminAttendanceTab> {
  List<Map<String, dynamic>> _allSchedules = [];
  bool _isLoading = true;

  late List<DateTime> _weekDays;
  late DateTime _selectedDate;

  String? _selectedYear = '1'; 
  String? _selectedDept = 'برمجيات'; 

  final List<String> _yearsList = ['1', '2', '3', '4'];
  final List<String> _deptsList = ['برمجيات', 'حواسيب', 'شبكات', 'تصميم', 'صيانة'];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _weekDays = List.generate(7, (index) => DateTime.now().subtract(Duration(days: index)));
    _loadAllSchedules();
  }

  Future<void> _loadAllSchedules() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client.from('schedules').select();
      if (mounted) setState(() => _allSchedules = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (mounted) _showSnackBar('خطأ في تحميل الجدول الدراسي: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Cairo'))));
  }

  String _getArabicDayName(DateTime date) {
    switch (date.weekday) {
      case 6: return 'السبت';
      case 7: return 'الأحد';
      case 1: return 'الإثنين';
      case 2: return 'الثلاثاء';
      case 3: return 'الأربعاء';
      case 4: return 'الخميس';
      case 5: default: return 'الجمعة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentArabicDay = _getArabicDayName(_selectedDate);

    final filteredSchedules = _allSchedules.where((s) {
      final dbDay = (s['day_of_week'] ?? '').toString().trim();
      final dbYear = (s['year'] ?? s['level'] ?? '1').toString().trim();
      final dbDept = (s['department'] ?? s['major'] ?? 'برمجيات').toString().trim();

      return dbDay == currentArabicDay && dbYear == _selectedYear && dbDept == _selectedDept;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة تفقّد الطلاب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Hierarchical Filter
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('فلترة القاعات والمحاضرات:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.lightTextMuted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        // --- الحماية الفولاذية ضد الشاشة الحمراء ---
                        value: _yearsList.contains(_selectedYear) ? _selectedYear : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF131C2E) : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: _yearsList.map((y) => DropdownMenuItem(value: y, child: Text('السنة $y', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (val) => setState(() => _selectedYear = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        // --- الحماية الفولاذية ضد الشاشة الحمراء ---
                        value: _deptsList.contains(_selectedDept) ? _selectedDept : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF131C2E) : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: _deptsList.map((d) => DropdownMenuItem(value: d, child: Text('قسم $d', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (val) => setState(() => _selectedDept = val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Date Picker Dock
          Container(
            height: 80, width: double.infinity,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)))),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _weekDays.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final d = _weekDays[index];
                final isSelected = d.day == _selectedDate.day && d.month == _selectedDate.month;
                final dayLabel = index == 0 ? 'اليوم' : _getArabicDayName(d);

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _selectedDate = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 65,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF131C2E) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.2), width: isSelected ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(dayLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87))),
                        const SizedBox(height: 2),
                        Text('${d.day}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, fontFamily: 'Roboto', color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Section Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('محاضرات يوم $currentArabicDay', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text('${filteredSchedules.length} قاعة متاحة', style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted)),
              ],
            ),
          ),

          // Schedules List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredSchedules.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text('لا توجد محاضرات في هذا اليوم للسنة ($_selectedYear) قسم ($_selectedDept)', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                        itemCount: filteredSchedules.length,
                        itemBuilder: (context, index) {
                          final sched = filteredSchedules[index];
                          final subject = sched['subject'] ?? 'مادة غير مسماة';
                          final time = '${sched['start_time']?.toString().substring(0,5)} - ${sched['end_time']?.toString().substring(0,5)}';
                          final room = sched['room'] ?? 'قاعة';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                        child: Text(room, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.lightTextMuted),
                                      const SizedBox(width: 6),
                                      Text(time, style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted, fontFamily: 'Roboto', fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
                                  
                                  SizedBox(
                                    width: double.infinity, height: 42,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary.withValues(alpha: 0.12), foregroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                      icon: const Icon(Icons.co_present_rounded, size: 18),
                                      label: const Text('فتح قائمة الطلاب وأخذ التفقّد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(
                                          builder: (_) => ClassRollCallScreen(
                                            schedule: sched, 
                                            date: _selectedDate,
                                            year: _selectedYear ?? '1',
                                            department: _selectedDept ?? 'برمجيات',
                                          ),
                                        ));
                                      },
                                    ),
                                  )
                                ],
                              ),
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


// ============================================================================
// 2. شاشة التفقّد الحية (مع زر الرجوع للفلترة + الدارك الصافي)
// ============================================================================
class ClassRollCallScreen extends StatefulWidget {
  final Map<String, dynamic> schedule;
  final DateTime date;
  final String year;
  final String department;

  const ClassRollCallScreen({super.key, required this.schedule, required this.date, required this.year, required this.department});

  @override
  State<ClassRollCallScreen> createState() => _ClassRollCallScreenState();
}

class _ClassRollCallScreenState extends State<ClassRollCallScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<UserModel> _targetStudents = [];
  final Map<String, String> _attendanceSnapshot = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadStudentsAndPreviousRoll();
  }

  Future<void> _loadStudentsAndPreviousRoll() async {
    setState(() => _isLoading = true);
    final dateString = widget.date.toIso8601String().substring(0, 10);

    try {
      final allStuds = await _supabaseService.getAllStudents();
      _targetStudents = allStuds.where((s) {
        final studYear = (s.year ?? '1').toString().trim();
        final studDept = (s.department ?? 'برمجيات').toString().trim();
        return studYear == widget.year && studDept == widget.department;
      }).toList();

      final existingRecords = await Supabase.instance.client
          .from('attendance')
          .select()
          .eq('schedule_id', widget.schedule['id'])
          .eq('date', dateString);

      final recordsMap = <String, String>{};
      for (var r in existingRecords) {
        recordsMap[r['student_id']?.toString() ?? ''] = r['status']?.toString() ?? 'present';
      }

      for (var s in _targetStudents) {
        _attendanceSnapshot[s.id] = recordsMap[s.id] ?? 'present';
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في جلب البيانات: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBatchRollCall() async {
    if (_targetStudents.isEmpty) return;
    setState(() => _isSaving = true);
    final dateString = widget.date.toIso8601String().substring(0, 10);

    try {
      final scheduleId = widget.schedule['id'];

      await Supabase.instance.client
          .from('attendance')
          .delete()
          .eq('schedule_id', scheduleId)
          .eq('date', dateString);

      final payload = _targetStudents.map((stud) {
        return {
          'student_id': stud.id,
          'schedule_id': scheduleId,
          'date': dateString,
          'status': _attendanceSnapshot[stud.id] ?? 'present',
        };
      }).toList();

      await Supabase.instance.client.from('attendance').insert(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم اعتماد تفقّد القاعة وحفظه بنجاح 💾', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حفظ السجل: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectName = widget.schedule['subject'] ?? 'المحاضرة';
    final dateStr = widget.date.toIso8601String().substring(0, 10);

    final pCount = _attendanceSnapshot.values.where((v) => v == 'present').length;
    final lCount = _attendanceSnapshot.values.where((v) => v == 'late').length;
    final aCount = _attendanceSnapshot.values.where((v) => v == 'absent').length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(subjectName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('سنة ${widget.year} • قسم ${widget.department} • $dateStr', style: const TextStyle(fontSize: 11, color: AppColors.lightTextMuted)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _targetStudents.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('لا يوجد طلاب مسجلين في المعهد ضمن السنة (${widget.year}) وقسم (${widget.department})', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold, height: 1.5)),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: isDark ? const Color(0xFF131C2E) : Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('🟢 حاضر: $pCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                          Text('🟠 متأخر: $lCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warning)),
                          Text('🔴 غائب: $aCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        itemCount: _targetStudents.length,
                        itemBuilder: (context, index) {
                          final stud = _targetStudents[index];
                          final currentSt = _attendanceSnapshot[stud.id] ?? 'present';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18, backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                    child: Text(stud.name.isNotEmpty ? stud.name[0] : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(stud.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                  
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildStatusPill(stud.id, 'present', 'حاضر', AppColors.success, currentSt),
                                      const SizedBox(width: 4),
                                      _buildStatusPill(stud.id, 'late', 'تأخر', AppColors.warning, currentSt),
                                      const SizedBox(width: 4),
                                      _buildStatusPill(stud.id, 'absent', 'غائب', AppColors.danger, currentSt),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _targetStudents.isEmpty ? null : SizedBox(
        width: MediaQuery.of(context).size.width * 0.9, height: 52,
        child: FloatingActionButton.extended(
          onPressed: _isSaving ? null : _saveBatchRollCall,
          backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          label: _isSaving 
              ? const CircularProgressIndicator(color: Colors.white)
              : Text('حفظ تفقّد القاعة واعتماده (${_targetStudents.length} طالب)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String studId, String targetStatus, String label, Color color, String currentStatus) {
    final isActive = currentStatus == targetStatus;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _attendanceSnapshot[studId] = targetStatus),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color : (isDark ? Colors.white10 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? color : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w900 : FontWeight.w600, color: isActive ? Colors.white : (isDark ? Colors.white60 : Colors.black54)),
        ),
      ),
    );
  }
}