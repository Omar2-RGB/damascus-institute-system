import 'dart:math'; // <--- مكتبة الرياضيات لتوليد المعرفات العشوائية
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
// أضفنا as fp في النهاية
import 'package:file_picker/file_picker.dart' as fp;
import 'package:excel/excel.dart' hide Border; // <--- حل مشكلة تعارض الأسماء
import '../../../../data/services/supabase_service.dart';
import '../../../../data/models/user_model.dart';
import '../../../../core/theme/app_colors.dart'; 
import 'AdminAttendanceTab.dart'; 
import 'dart:io';
class AdminStudentsTab extends StatefulWidget {
  const AdminStudentsTab({super.key});

  @override
  State<AdminStudentsTab> createState() => _AdminStudentsTabState();
}

class _AdminStudentsTabState extends State<AdminStudentsTab> {
  final SupabaseService _supabaseService = SupabaseService();
  List<UserModel> _students = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await _supabaseService.getAllStudents();
      if (mounted) setState(() => _students = students);
    } catch (e) {
      if (mounted) _showSnackBar('خطأ في جلب بيانات الطلاب: $e', isError: true);
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _copyToClipboard(String? text, String label) {
    if (text == null || text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('تم نسخ $label: $text');
  }

  // ==================== ميزة الاحتراف: الاستيراد الجماعي من Excel ====================
  Future<void> _importFromExcel() async {
    // --- مولد الـ ID السحري ---
    String generateUuid() {
      final random = Random();
      const hexDigits = "0123456789abcdef";
      String uuid = "";
      for (int i = 0; i < 36; i++) {
        if (i == 8 || i == 13 || i == 18 || i == 23) {
          uuid += "-";
        } else if (i == 14) {
          uuid += "4";
        } else if (i == 19) {
          uuid += hexDigits[(random.nextInt(16) & 0x3) | 0x8];
        } else {
          uuid += hexDigits[random.nextInt(16)];
        }
      }
      return uuid;
    }

    try {
     // استخدمنا fp. قبل كل كلاس يخص المكتبة
      fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      // التأكد من المسار باستخدام dart:io كما اتفقنا
      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);

        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        var excel = Excel.decodeBytes(bytes);
        
        // ... (باقي الكود الخاص بقراءة الإكسل كما هو)
        List<Map<String, dynamic>> studentsList = [];

        var table = excel.tables.keys.first;
        var sheet = excel.tables[table]!;

       // تجاوز الصف الأول (عناوين الأعمدة)
        for (var i = 1; i < sheet.rows.length; i++) {
          var row = sheet.rows[i];
          if (row.isEmpty || row[0]?.value == null) continue;

          studentsList.add({
            'id': generateUuid(), 
            'name': row[0]?.value?.toString().trim() ?? '',
            'student_id': row[1]?.value?.toString().trim() ?? '', // <--- تم التبديل لتطابق الإكسل
            'email': row[2]?.value?.toString().trim() ?? '',      // <--- تم التبديل لتطابق الإكسل
            'department': row[3]?.value?.toString().trim() ?? '',
            'year': int.tryParse(row[4]?.value?.toString() ?? '1'),
            'role': 'student',
          });
        }
        
        if (studentsList.isEmpty) {
          if (mounted) _showSnackBar('الملف فارغ أو التنسيق غير صحيح', isError: true);
          setState(() => _isLoading = false);
          return;
        }

        await _supabaseService.bulkAddStudents(studentsList);
        await _loadStudents(); 
        
        if (mounted) _showSnackBar('تم استيراد ${studentsList.length} طالب بنجاح! 🚀');
      }
    } catch (e) {
      if (mounted) _showSnackBar('حدث خطأ أثناء قراءة ملف الإكسل: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  // --- صمام أمان الحذف ---
  Future<void> _confirmAndDeleteStudent(UserModel student) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isDark ? const Color(0xFF222F4A) : Colors.transparent)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_off_rounded, color: AppColors.danger, size: 48),
              const SizedBox(height: 16),
              Text('حذف قيد الطالب؟', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text('هل أنت متأكد من رغبتك في حذف الطالب "${student.name}"؟ ستتم إزالة كافة سجلاته.', textAlign: TextAlign.center, style: TextStyle(color: mutedColor, fontSize: 13, height: 1.4)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => Navigator.pop(context, false), 
                      child: Text('تراجع', style: TextStyle(color: mutedColor, fontWeight: FontWeight.bold))
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                      onPressed: () => Navigator.pop(context, true), 
                      child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold))
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deleteStudent(student.id);
        await _loadStudents();
        if (mounted) _showSnackBar('تم حذف قيد الطالب بنجاح');
      } catch (e) {
        if (mounted) _showSnackBar('خطأ في الحذف: $e', isError: true);
      }
    }
  }

  // --- BottomSheet موحد (إضافة / تعديل الطالب يدويًا) ---
  void _openStudentModal([UserModel? existingStudent]) {
    final isEditing = existingStudent != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final nameController = TextEditingController(text: isEditing ? existingStudent.name : '');
    final emailController = TextEditingController(text: isEditing ? existingStudent.email : '');
    final passwordController = TextEditingController(); 
    final studentIdController = TextEditingController(text: isEditing ? (existingStudent.studentId ?? '') : '');
    final deptController = TextEditingController(text: isEditing ? (existingStudent.department ?? '') : '');
    final yearController = TextEditingController(text: isEditing ? (existingStudent.year?.toString() ?? '') : '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 20, right: 20, top: 16),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(isEditing ? 'تعديل بيانات الطالب' : 'تسجيل طالب جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 20),

              _buildCustomTextField(controller: nameController, label: 'الاسم الثلاثي *', icon: Icons.person_rounded, isDark: isDark),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(flex: 3, child: _buildCustomTextField(controller: studentIdController, label: 'الرقم الجامعي', icon: Icons.badge_rounded, isNumber: true, isDark: isDark)),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: _buildCustomTextField(controller: yearController, label: 'السنة', icon: Icons.school_rounded, isNumber: true, isDark: isDark)),
                ],
              ),
              const SizedBox(height: 12),
              _buildCustomTextField(controller: deptController, label: 'القسم (مثال: حواسيب / برمجيات)', icon: Icons.account_balance_rounded, isDark: isDark),
              
              Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Divider(color: Colors.grey.withValues(alpha: 0.15))),

              _buildCustomTextField(controller: emailController, label: 'البريد الإلكتروني *', icon: Icons.email_rounded, isEmail: true, isDark: isDark),
              
              if (!isEditing) ...[
                const SizedBox(height: 12),
                _buildCustomTextField(controller: passwordController, label: 'كلمة المرور المؤقتة *', icon: Icons.lock_rounded, isPassword: true, isDark: isDark),
              ],

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
                        await _supabaseService.updateStudent(existingStudent.id, {
                          'name': nameController.text.trim(),
                          'email': emailController.text.trim(),
                          'student_id': studentIdController.text.trim().isEmpty ? null : studentIdController.text.trim(),
                          'department': deptController.text.trim().isEmpty ? null : deptController.text.trim(),
                          'year': yearController.text.trim().isEmpty ? null : int.tryParse(yearController.text.trim()),
                        });
                        if (mounted) _showSnackBar('تم تحديث بيانات الطالب');
                      } else {
                        await _supabaseService.addStudent(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                          role: 'student',
                          studentId: studentIdController.text.trim().isEmpty ? null : studentIdController.text.trim(),
                          department: deptController.text.trim().isEmpty ? null : deptController.text.trim(),
                          year: yearController.text.trim().isEmpty ? null : int.tryParse(yearController.text.trim()),
                        );
                        if (mounted) _showSnackBar('تم إنشاء حساب الطالب بنجاح');
                      }
                      await _loadStudents();
                    } catch (e) {
                      if (mounted) _showSnackBar('خطأ: $e', isError: true);
                    }
                  },
                  child: Text(isEditing ? 'حفظ التعديلات' : 'إنشاء الحساب', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextField({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false, bool isEmail = false, bool isPassword = false, required bool isDark}) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final fillColor = isDark ? const Color(0xFF131C2E) : Colors.grey.shade100;

    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : (isEmail ? TextInputType.emailAddress : TextInputType.text),
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
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final filteredList = _searchQuery.isEmpty
        ? _students
        : _students.where((s) {
            final name = s.name.toLowerCase();
            final email = s.email.toLowerCase();
            final sId = (s.studentId ?? '').toLowerCase();
            final q = _searchQuery.toLowerCase();
            return name.contains(q) || email.contains(q) || sId.contains(q);
          }).toList();

    return Scaffold(
      body: Column(
        children: [
          // --- 1. Header & Omni Search Box ---
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('سجل الطلاب العام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Text('${_students.length} طالب', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    )
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(fontSize: 13, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم، البريد، أو الرقم الجامعي...',
                    hintStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                    suffixIcon: _searchQuery.isEmpty ? null : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                    filled: true, fillColor: isDark ? const Color(0xFF131C2E) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // --- 2. Students Directory List ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredList.isEmpty
                    ? _buildEmptyPlaceholder(isDark)
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadStudents,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final student = filteredList[index];
                            final sId = student.studentId ?? '';
                            final dept = student.department ?? '';
                            final year = student.year?.toString() ?? '';

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 14),
                              color: isDark ? const Color(0xFF131C2E) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isDark ? const Color(0xFF222F4A) : Colors.grey.shade200)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                          child: Text(student.name.isNotEmpty ? student.name[0] : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(student.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                                              const SizedBox(height: 4),
                                              if (dept.isNotEmpty || year.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(6)),
                                                  child: Text(
                                                    [if (dept.isNotEmpty) dept, if (year.isNotEmpty) 'سنة $year'].join(' • '),
                                                    style: TextStyle(fontSize: 11, color: mutedColor, fontWeight: FontWeight.w600),
                                                  ),
                                                )
                                              else
                                                Text(student.email, style: TextStyle(fontSize: 12, color: mutedColor)),
                                            ],
                                          ),
                                        ),

                                        FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.1),
                                            foregroundColor: AppColors.primary,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          icon: const Icon(Icons.analytics_rounded, size: 14),
                                          label: const Text('الحضور', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const AdminAttendanceTab(), 
                                              ),
                                            );
                                          },
                                        )
                                      ],
                                    ),

                                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15))),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: sId.isNotEmpty ? () => _copyToClipboard(sId, 'الرقم الجامعي') : null,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.qr_code_rounded, size: 12, color: AppColors.lightTextMuted),
                                                const SizedBox(width: 4),
                                                Text(sId.isNotEmpty ? 'ID: $sId' : 'بدون رقم جامعي', style: TextStyle(fontSize: 11, fontFamily: 'Roboto', fontWeight: FontWeight.bold, color: mutedColor)),
                                              ],
                                            ),
                                          ),
                                        ),

                                        Row(
                                          children: [
                                            InkWell(onTap: () => _openStudentModal(student), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_rounded, size: 17, color: Colors.blue))),
                                            const SizedBox(width: 12),
                                            InkWell(onTap: () => _confirmAndDeleteStudent(student), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline_rounded, size: 17, color: Colors.redAccent))),
                                          ],
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),

     // --- أزرار التحكم العائمة للطلاب ---
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // زر تفعيل الحسابات (الجديد)
          FloatingActionButton.extended(
            heroTag: 'generate_accounts_btn',
          onPressed: () async {
              setState(() => _isLoading = true);
              try {
                // استلام الرسالة الناطقة من الداتا بيز
                final msg = await _supabaseService.generateStudentAccounts();
                if (mounted) {
                  // إذا رجع نجاح نعطيه لون أخضر، وإذا تنبيه لون أصفر/أحمر
                  final isSuccess = msg.contains('نجاح');
                  _showSnackBar(msg, isError: !isSuccess);
                }
              } catch (e) {
                if (mounted) _showSnackBar('حدث خطأ: $e', isError: true);
              } finally {
                setState(() => _isLoading = false);
              }
            },

            backgroundColor: const Color(0xFF3B82F6), // Blue
            foregroundColor: Colors.white,
            icon: const Icon(Icons.vpn_key_rounded, size: 20),
            label: const Text('تفعيل حسابات الدخول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'import_excel_btn',
                onPressed: _importFromExcel,
                backgroundColor: const Color(0xFF10B981), // Emerald Green
                foregroundColor: Colors.white,
                tooltip: 'استيراد جماعي عبر Excel',
                child: const Icon(Icons.table_view_rounded),
              ),
              const SizedBox(width: 12),
              FloatingActionButton.extended(
                heroTag: 'add_student_btn',
                onPressed: () => _openStudentModal(),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.person_add_rounded, size: 20),
                label: const Text('إضافة طالب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyPlaceholder(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_searchQuery.isEmpty ? Icons.school_outlined : Icons.search_off_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty ? 'لا يوجد طلاب مسجلين في السيستم' : 'لا يوجد طالب يطابق "$_searchQuery"',
            style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}