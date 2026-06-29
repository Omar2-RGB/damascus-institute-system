import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import '../../../../data/services/supabase_service.dart';
import '../../../../data/models/user_model.dart';
import '../../../../core/theme/app_colors.dart'; 
import 'dart:io';
class AdminGradesTab extends StatefulWidget {
  const AdminGradesTab({super.key});

  @override
  State<AdminGradesTab> createState() => _AdminGradesTabState();
}

class _AdminGradesTabState extends State<AdminGradesTab> {
  final SupabaseService _supabaseService = SupabaseService();
  List<UserModel> _students = [];
  UserModel? _selectedStudent;
  List<Map<String, dynamic>> _grades = [];
  bool _isLoading = true;

  final Color _tabPurple = const Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await _supabaseService.getAllStudents();
      if (mounted) setState(() => _students = students);
    } catch (e) {
      if (mounted) _showSnackBar('خطأ في تحميل أسماء الطلاب', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGrades(String studentId) async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getGrades(studentId);
      if (mounted) setState(() => _grades = data);
    } catch (e) {
      if (mounted) _showSnackBar('خطأ في تحميل العلامات', isError: true);
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
        duration: const Duration(seconds: 4),
      ),
    );
  }
// ==================== محرك استيراد قالب المعهد التقاني (درعا) المعتمد ====================
  Future<void> _importGradesFromExcel() async {
    try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
     type: FileType.custom,
     allowedExtensions: ['xlsx'],
   );

   // نعتمد على path بدلاً من xFile أو bytes
   if (result != null && result.files.single.path != null) {
     setState(() => _isLoading = true);

     // قراءة الملف عبر dart:io الأساسية
     final file = File(result.files.single.path!);
     final bytes = await file.readAsBytes();
     var excel = Excel.decodeBytes(bytes);
        List<Map<String, dynamic>> gradesList = [];
        int skippedCount = 0;

        var table = excel.tables.keys.first;
        var sheet = excel.tables[table]!;

        // 1. --- الصيّاد الذكي للترويسة (لقراءة اسم المادة والفصل تلقائياً من فوق) ---
        String detectedSubject = 'مادة غير محددة';
        String detectedSemester = 'الفصل الدراسي الثاني';
        double detectedPracMax = 40.0;

        // تابع داخلي يبحث في أول 10 أسطر عن كلمة معينة ويسحب القيمة التي بجانبها
        String searchHeader(String keyword, String fallback) {
          for (int r = 0; r < 10 && r < sheet.rows.length; r++) {
            final row = sheet.rows[r];
            for (int c = 0; c < row.length; c++) {
              final text = row[c]?.value?.toString().trim() ?? '';
              if (text.contains(keyword)) {
                // حالة أ: إذا كانت مكتوبة بخلية واحدة (مثال: "اسم المادة : برمجة 1")
                if (text.contains(':')) {
                  final parts = text.split(':');
                  if (parts.length > 1 && parts.last.trim().isNotEmpty) {
                    return parts.last.trim();
                  }
                }
                // حالة ب: مكتوبة بالخلية التي جنبها مباشرة (يمين أو يسار حسب لغة الأوفيس)
                if (c + 1 < row.length && row[c + 1]?.value != null) {
                  final val = row[c + 1]!.value!.toString().trim();
                  if (val.isNotEmpty && val != ':') return val;
                }
                if (c - 1 >= 0 && row[c - 1]?.value != null) {
                  final val = row[c - 1]!.value!.toString().trim();
                  if (val.isNotEmpty && val != ':') return val;
                }
              }
            }
          }
          return fallback;
        }

        detectedSubject = searchHeader('اسم المادة', 'برمجة 1');
        detectedSemester = searchHeader('الفصل الدراسي', 'الفصل الدراسي الثاني');
        
        final maxStr = searchHeader('النهاية العظمى', '40');
        detectedPracMax = double.tryParse(maxStr) ?? 40.0;

        // 2. --- قراءة جدول الطلاب (يبدأ الشفط فوراً عند أول رقم امتحاني حقيقي) ---
        for (var i = 0; i < sheet.rows.length; i++) {
          var row = sheet.rows[i];
          if (row.length < 8) continue; // تخطي الأسطر التالفة أو القصيرة

          // العمود [1] هو (الرقم الامتحاني / الرقم الجامعي) حسب جدول المعهد
          final rawIdCell = row[1]?.value?.toString().trim() ?? '';

          // *** الفلتر السحري *** 
          // أي سطر عموده الثاني ليس رقماً (مثل سطر العناوين "الرقم الامتحاني" أو ترويسة جامعة دمشق فوق) سيتخطاه فوراً
          if (int.tryParse(rawIdCell) == null) continue;

          final rawStudentId = rawIdCell;

          // العمود [7] هو (الدرجة النهائية رقماً) وهو يمثل المجموع الكلي لأعمال الطالب (24+8+8)
          final pracMark = double.tryParse(row[7]?.value?.toString() ?? '0') ?? 0.0;

          UserModel? matchedStudent;
          try {
            matchedStudent = _students.firstWhere((s) => s.studentId == rawStudentId);
          } catch (_) {
            skippedCount++;
            continue; // طالب مو مسجل بقاعدة بياناتنا، تخطاه بصمت
          }

          gradesList.add({
            'student_id': matchedStudent.id,
            'subject': detectedSubject,
            'semester': detectedSemester,
            'practical_mark': pracMark,
            'practical_max': detectedPracMax,
            'theoretical_mark': null, // لسا ما قدموا النظري
            'theoretical_max': 100.0 - detectedPracMax, // إكمال المئة تلقائياً (مثلاً 60)
            'passing_min': 60.0,
            'grade': pracMark,
            'max_grade': 100.0,
            'status': 'غير مكتمل', // الحالة معلقة لبين ما ينرصد النظري
          });
        }

        if (gradesList.isEmpty) {
          if (mounted) _showSnackBar('الملف لا يحتوي على أرقام امتحانية مطابقة لطلاب النظام!', isError: true);
          setState(() => _isLoading = false);
          return;
        }

        await _supabaseService.bulkAddGrades(gradesList);

        if (_selectedStudent != null) {
          await _loadGrades(_selectedStudent!.id);
        } else {
          setState(() => _isLoading = false);
        }

        if (mounted) {
          _showSnackBar(
            'تم رصد ${gradesList.length} علامة لمادة "$detectedSubject" بنجاح! 🚀${skippedCount > 0 ? '\n(تم تخطي $skippedCount أسطر لطلاب غير معرفين بالنظام)' : ''}'
          );
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('حدث خطأ أثناء معالجة قالب المعهد: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }
  UserModel? _getSafeStudent() {
    if (_selectedStudent == null) return null;
    try {
      return _students.firstWhere((s) => s.id == _selectedStudent!.id);
    } catch (_) {
      return null;
    }
  }

  double _calculateStudentAverage() {
    if (_grades.isEmpty) return 0.0;
    double sum = 0;
    for (var g in _grades) {
      final val = double.tryParse(g['grade']?.toString() ?? '0') ?? 0;
      final max = double.tryParse(g['max_grade']?.toString() ?? '100') ?? 100;
      if (max > 0) sum += (val / max) * 100;
    }
    return sum / _grades.length;
  }

  Future<void> _confirmAndDeleteGrade(String gradeId, String subjectName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
        final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

        return Dialog(
          backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, color: AppColors.danger, size: 48),
                const SizedBox(height: 16),
                Text('حذف السجل؟', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text('هل أنت متأكد من رغبتك في حذف علامة مادة "$subjectName"؟', textAlign: TextAlign.center, style: TextStyle(color: mutedColor, fontSize: 14)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => Navigator.pop(context, false), 
                        child: Text('إلغاء', style: TextStyle(color: mutedColor, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                        onPressed: () => Navigator.pop(context, true), 
                        child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      try {
        await _supabaseService.deleteGrade(gradeId);
        if (_selectedStudent != null) await _loadGrades(_selectedStudent!.id);
        if (mounted) _showSnackBar('تم حذف العلامة بنجاح');
      } catch (e) {
        if (mounted) _showSnackBar('خطأ في الحذف: $e', isError: true);
      }
    }
  }

  void _openGradeModal([Map<String, dynamic>? existingGrade]) {
    if (_selectedStudent == null) return;
    final isEditing = existingGrade != null;
    
    final subjectController = TextEditingController(text: isEditing ? existingGrade['subject'] : '');
    final semesterController = TextEditingController(text: isEditing ? existingGrade['semester'] : 'الفصل الأول');

    final pracMarkController = TextEditingController(text: isEditing ? existingGrade['practical_mark']?.toString() : '');
    final pracMaxController = TextEditingController(text: isEditing ? (existingGrade['practical_max']?.toString() ?? '30') : '30');
    
    final theoMarkController = TextEditingController(text: isEditing ? existingGrade['theoretical_mark']?.toString() : '');
    final theoMaxController = TextEditingController(text: isEditing ? (existingGrade['theoretical_max']?.toString() ?? '70') : '70');

    final passingMinController = TextEditingController(text: isEditing ? (existingGrade['passing_min']?.toString() ?? '60') : '60');

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
        final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

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
                Text(isEditing ? 'تعديل علامة المادة' : 'رصد علامة مادة جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 4),
                Text('الطالب: ${_selectedStudent!.name}', style: TextStyle(fontSize: 13, color: _tabPurple, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(flex: 2, child: _buildTextField(controller: subjectController, label: 'اسم المادة *', icon: Icons.book_rounded, isDark: isDark)),
                    const SizedBox(width: 10),
                    Expanded(flex: 1, child: _buildTextField(controller: semesterController, label: 'الفصل *', icon: Icons.flag_rounded, isDark: isDark)),
                  ],
                ),

                Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Divider(color: Colors.grey.withValues(alpha: 0.15))),

                Text('علامة العملي (المذاكرة)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mutedColor)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: pracMarkController, label: 'العلامة المجمّعة', icon: Icons.biotech_rounded, isNum: true, isDark: isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(controller: pracMaxController, label: 'من أصل (30 أو 40) *', icon: Icons.done_all_rounded, isNum: true, isDark: isDark)),
                  ],
                ),

                const SizedBox(height: 14),

                Text('علامة الفحص النظري النهائي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mutedColor)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: theoMarkController, label: 'علامة الورقة', icon: Icons.quiz_rounded, isNum: true, isDark: isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(controller: theoMaxController, label: 'من أصل (60 أو 70) *', icon: Icons.done_all_rounded, isNum: true, isDark: isDark)),
                  ],
                ),

                const SizedBox(height: 14),
                _buildTextField(controller: passingMinController, label: 'الحد الأدنى للنجاح بالمادة (50 أو 60) *', icon: Icons.rule_rounded, isNum: true, isDark: isDark),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _tabPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final pracMark = double.tryParse(pracMarkController.text.trim());
                      final pracMax = double.tryParse(pracMaxController.text.trim()) ?? 30.0;

                      final theoMark = double.tryParse(theoMarkController.text.trim());
                      final theoMax = double.tryParse(theoMaxController.text.trim()) ?? 70.0;

                      final passingMin = double.tryParse(passingMinController.text.trim()) ?? 60.0;

                      if (pracMark != null && pracMark > pracMax) {
                        _showSnackBar('علامة العملي ($pracMark) لا يمكن أن تتجاوز العظمى ($pracMax)', isError: true);
                        return;
                      }
                      if (theoMark != null && theoMark > theoMax) {
                        _showSnackBar('علامة النظري ($theoMark) لا يمكن أن تتجاوز العظمى ($theoMax)', isError: true);
                        return;
                      }

                      final computedTotal = (pracMark ?? 0.0) + (theoMark ?? 0.0);
                      final computedMax = pracMax + theoMax;
                      
                      final computedStatus = theoMark == null 
                          ? 'غير مكتمل' 
                          : (computedTotal >= passingMin ? 'ناجح' : 'راسب');

                      Navigator.pop(context);
                      try {
                        final payload = {
                          'subject': subjectController.text.trim(),
                          'semester': semesterController.text.trim(),
                          'practical_mark': pracMark,
                          'practical_max': pracMax,
                          'theoretical_mark': theoMark,
                          'theoretical_max': theoMax,
                          'passing_min': passingMin,
                          'grade': computedTotal, 
                          'max_grade': computedMax,
                          'status': computedStatus,
                        };

                        if (isEditing) {
                          await _supabaseService.updateGrade(existingGrade['id'], payload);
                          if (mounted) _showSnackBar('تم تعديل السجل وتحديث الحالة');
                        } else {
                          final newRecord = {
                            'student_id': _selectedStudent!.id,
                            ...payload,
                          };
                          await _supabaseService.bulkAddGrades([newRecord]);
                          if (mounted) _showSnackBar('تم رصد العلامة بنجاح');
                        }
                        await _loadGrades(_selectedStudent!.id);
                      } catch (e) {
                        if (mounted) _showSnackBar('خطأ: $e', isError: true);
                      }
                    },
                    child: Text(isEditing ? 'حفظ التعديلات' : 'اعتماد ورصد العلامة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isNum = false, required bool isDark}) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final fillColor = isDark ? const Color(0xFF131C2E) : Colors.grey.shade100;

    return TextFormField(
      controller: controller,
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 11),
        prefixIcon: Icon(icon, color: _tabPurple, size: 16),
        filled: true, fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: _tabPurple, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: (v) => label.contains('*') && (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final avg = _calculateStudentAverage();
    final safeStudent = _getSafeStudent();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface, 
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))], 
              border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إدارة السجلات الأكاديمية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserModel>(
                  value: safeStudent, 
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: _tabPurple),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person_search_rounded, color: _tabPurple),
                    filled: true, fillColor: isDark ? const Color(0xFF131C2E) : const Color(0xFFF8FAFC),
                    hintText: 'اختر طالباً من سجل المعهد...',
                    hintStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _students.map((s) => DropdownMenuItem<UserModel>(value: s, child: Text(s.name, style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 14)))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedStudent = val);
                    if (val != null) _loadGrades(val.id);
                  },
                ),
              ],
            ),
          ),

          if (safeStudent != null && !_isLoading && _grades.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _tabPurple.withValues(alpha: isDark ? 0.15 : 0.08), 
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(color: _tabPurple.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics_rounded, color: _tabPurple, size: 20),
                        const SizedBox(width: 8),
                        Text('المعدل التراكمي للطالب:', style: TextStyle(fontSize: 13, color: mutedColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _tabPurple, borderRadius: BorderRadius.circular(8)),
                      child: Text('${avg.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontFamily: 'Roboto', fontSize: 14)),
                    )
                  ],
                ),
              ),
            ),

          Expanded(
            child: safeStudent == null
                ? _buildEmptyState(Icons.how_to_reg_rounded, 'قم بتحديد طالب من القائمة العلوية لاستعراض وإدارة علاماته', isDark)
                : _isLoading
                    ? Center(child: CircularProgressIndicator(color: _tabPurple))
                    : _grades.isEmpty
                        ? _buildEmptyState(Icons.assignment_late_outlined, 'لم يتم رصد أي علامات لهذا الطالب حتى الآن', isDark)
                        : RefreshIndicator(
                            color: _tabPurple,
                            onRefresh: () => _loadGrades(safeStudent.id),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _grades.length,
                              itemBuilder: (context, index) {
                                final g = _grades[index];
                                final subject = g['subject'] ?? '';
                                
                                final totalVal = double.tryParse(g['grade']?.toString() ?? '0') ?? 0;
                                final maxVal = double.tryParse(g['max_grade']?.toString() ?? '100') ?? 100;
                                
                                final pracMark = double.tryParse(g['practical_mark']?.toString() ?? '');
                                final pracMax = double.tryParse(g['practical_max']?.toString() ?? '30') ?? 30;
                                
                                final theoMark = double.tryParse(g['theoretical_mark']?.toString() ?? '');
                                final theoMax = double.tryParse(g['theoretical_max']?.toString() ?? '70') ?? 70;

                                final statusVal = g['status']?.toString() ?? (theoMark == null ? 'غير مكتمل' : (totalVal >= 60 ? 'ناجح' : 'راسب'));
                                final isPassedStatus = statusVal == 'ناجح';
                                final isPendingStatus = statusVal == 'غير مكتمل';

                                final badgeColor = isPendingStatus ? AppColors.warning : (isPassedStatus ? AppColors.success : AppColors.danger);
                                final badgeBg = badgeColor.withValues(alpha: 0.15);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF131C2E) : Colors.white, 
                                    borderRadius: BorderRadius.circular(18), 
                                    border: Border.all(color: isDark ? const Color(0xFF222F4A) : Colors.grey.shade200),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(subject, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                                              const SizedBox(height: 2),
                                              Text(g['semester'] ?? '', style: TextStyle(fontSize: 11, color: mutedColor)),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                                            child: Text(
                                              isPendingStatus ? '⏳ غير مكتمل' : (isPassedStatus ? '🟢 ناجح' : '🔴 راسب'),
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                                            ),
                                          )
                                        ],
                                      ),

                                      Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15))),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text('عملي: ${pracMark != null ? pracMark.toInt() : "?"}/${pracMax.toInt()}', style: TextStyle(fontSize: 11, color: mutedColor, fontWeight: FontWeight.w600)),
                                              const Text('  •  ', style: TextStyle(color: Colors.grey)),
                                              Text('نظري: ${theoMark != null ? theoMark.toInt() : "?"}/${theoMax.toInt()}', style: TextStyle(fontSize: 11, color: mutedColor, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                          Text(
                                            '${totalVal == totalVal.toInt() ? totalVal.toInt() : totalVal}/${maxVal.toInt()}',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Roboto', color: textColor),
                                          )
                                        ],
                                      ),

                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          InkWell(onTap: () => _openGradeModal(g), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_rounded, size: 17, color: Colors.blue))),
                                          const SizedBox(width: 14),
                                          InkWell(onTap: () => _confirmAndDeleteGrade(g['id'], subject), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline_rounded, size: 17, color: Colors.redAccent))),
                                        ],
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'import_grades_excel',
            onPressed: _importGradesFromExcel,
            backgroundColor: const Color(0xFF10B981), 
            foregroundColor: Colors.white,
            tooltip: 'استيراد علامات عبر Excel',
            child: const Icon(Icons.table_view_rounded),
          ),
          
          if (safeStudent != null) ...[
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'add_single_grade',
              onPressed: () => _openGradeModal(),
              backgroundColor: _tabPurple,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task_rounded, size: 20),
              label: const Text('رصد علامة يدوية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String text, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade100, shape: BoxShape.circle), child: Icon(icon, size: 48, color: Colors.grey.withValues(alpha: 0.4))),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600, height: 1.5)),
          ],
        ),
      ),
    );
  }
}