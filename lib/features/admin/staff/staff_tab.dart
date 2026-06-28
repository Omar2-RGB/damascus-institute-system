import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../../../../data/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart'; // <--- مخزن الألوان الموحد للمعهد

class AdminStaffTab extends StatefulWidget {
  const AdminStaffTab({super.key});

  @override
  State<AdminStaffTab> createState() => _AdminStaffTabState();
}

class _AdminStaffTabState extends State<AdminStaffTab> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _staff = [];
  bool _isLoading = true;
  
  // الرمز اللوني الزمردي الخاص بتبويب الأساتذة
  final Color _staffEmerald = const Color(0xFF059669);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getAllStaff();
      if (mounted) setState(() => _staff = data);
    } catch (e) {
      if (mounted) _showSnackBar('خطأ في تحميل بيانات الأساتذة', isError: true);
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('تم نسخ $label: $text');
  }

  Future<void> _confirmAndDeleteStaff(String id, String name) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
        final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

        return Dialog(
          backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isDark ? const Color(0xFF222F4A) : Colors.transparent)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.person_remove_rounded, color: AppColors.danger, size: 36),
                ),
                const SizedBox(height: 16),
                Text('حذف أستاذ؟', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text('هل أنت متأكد من حذف "$name" من سجلات المعهد؟', textAlign: TextAlign.center, style: TextStyle(color: mutedColor, fontSize: 13, height: 1.4)),
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
        );
      },
    );

    if (confirm == true) {
      try {
        await _supabaseService.deleteStaff(id);
        await _loadStaff();
        _showSnackBar('تم حذف بيانات الأستاذ');
      } catch (e) {
        if (mounted) _showSnackBar('خطأ في الحذف: $e', isError: true);
      }
    }
  }

  void _openStaffModal([Map<String, dynamic>? existingStaff]) {
    final isEditing = existingStaff != null;

    final nameController = TextEditingController(text: isEditing ? existingStaff['name'] : '');
    final titleController = TextEditingController(text: isEditing ? existingStaff['title'] : '');
    final emailController = TextEditingController(text: isEditing ? existingStaff['email'] : '');
    final phoneController = TextEditingController(text: isEditing ? existingStaff['phone'] : '');
    final specializationController = TextEditingController(text: isEditing ? existingStaff['specialization'] : '');
    final officeHoursController = TextEditingController(text: isEditing ? existingStaff['office_hours'] : '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
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
                Text(isEditing ? 'تعديل بيانات المدرس' : 'إضافة عضو هيئة تدريس جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(flex: 2, child: _buildCustomTextField(controller: nameController, label: 'الاسم الكامل *', icon: Icons.person_rounded, isDark: isDark)),
                    const SizedBox(width: 10),
                    Expanded(flex: 1, child: _buildCustomTextField(controller: titleController, label: 'اللقب (دكتور/م.)', icon: Icons.school_rounded, isDark: isDark)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCustomTextField(controller: specializationController, label: 'التخصص الأكاديمي (مثال: هندسة برمجيات)', icon: Icons.workspace_premium_rounded, isDark: isDark),
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Colors.grey.withValues(alpha: 0.15)),
                ),

                Row(
                  children: [
                    Expanded(child: _buildCustomTextField(controller: phoneController, label: 'رقم الهاتف', icon: Icons.phone_rounded, isPhone: true, isDark: isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildCustomTextField(controller: officeHoursController, label: 'ساعات التواجد', icon: Icons.access_time_filled_rounded, isDark: isDark)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCustomTextField(controller: emailController, label: 'البريد الإلكتروني', icon: Icons.email_rounded, isDark: isDark),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _staffEmerald, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(context);
                      try {
                        final payload = {
                          'name': nameController.text.trim(),
                          'title': titleController.text.trim().isEmpty ? null : titleController.text.trim(),
                          'email': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                          'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                          'specialization': specializationController.text.trim().isEmpty ? null : specializationController.text.trim(),
                          'office_hours': officeHoursController.text.trim().isEmpty ? null : officeHoursController.text.trim(),
                        };

                        if (isEditing) {
                          await _supabaseService.updateStaff(existingStaff['id'], payload);
                          if (mounted) _showSnackBar('تم تحديث بيانات الأستاذ');
                        } else {
                          await _supabaseService.addStaff(
                            name: payload['name'] as String,
                            title: payload['title'] as String?,
                            email: payload['email'] as String?,
                            phone: payload['phone'] as String?,
                            specialization: payload['specialization'] as String?,
                            officeHours: payload['office_hours'] as String?,
                          );
                          if (mounted) _showSnackBar('تمت إضافة الأستاذ بنجاح');
                        }
                        await _loadStaff();
                      } catch (e) {
                        if (mounted) _showSnackBar('خطأ: $e', isError: true);
                      }
                    },
                    child: Text(isEditing ? 'حفظ التعديلات' : 'اعتماد المدرس', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomTextField({required TextEditingController controller, required String label, required IconData icon, bool isPhone = false, bool isDark = false, bool isEmail = false}) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final fillColor = isDark ? const Color(0xFF131C2E) : Colors.grey.shade100;

    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 12),
        prefixIcon: Icon(icon, color: _staffEmerald, size: 18),
        filled: true, fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: _staffEmerald, width: 1.5)),
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

    final filteredList = _searchQuery.isEmpty
        ? _staff
        : _staff.where((s) {
            final name = (s['name'] ?? '').toString().toLowerCase();
            final spec = (s['specialization'] ?? '').toString().toLowerCase();
            final q = _searchQuery.toLowerCase();
            return name.contains(q) || spec.contains(q);
          }).toList();

    return Scaffold(
      body: Column(
        children: [
          // --- 1. Header & Live Search Bar ---
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
                    Text('الهيئة التدريسية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _staffEmerald.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Text('${_staff.length} مدرّس', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _staffEmerald)),
                    )
                  ],
                ),
                const SizedBox(height: 14),
                // Search Box
                TextFormField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(fontSize: 13, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'اببحث عن أستاذ بالاسم أو التخصص...',
                    hintStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: _staffEmerald, size: 20),
                    suffixIcon: _searchQuery.isEmpty ? null : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                    filled: true, 
                    fillColor: isDark ? const Color(0xFF131C2E) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // --- 2. Staff Directory List ---
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _staffEmerald))
                : filteredList.isEmpty
                    ? _buildPlaceholder(isDark)
                    : RefreshIndicator(
                        color: _staffEmerald,
                        onRefresh: _loadStaff,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final s = filteredList[index];
                            final id = s['id'] ?? '';
                            final name = s['name'] ?? 'مدرّس';
                            final title = s['title'] ?? '';
                            final spec = s['specialization'] ?? '';
                            final email = s['email'] ?? '';
                            final phone = s['phone'] ?? '';
                            final office = s['office_hours'] ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF131C2E) : Colors.white, 
                                borderRadius: BorderRadius.circular(20), 
                                border: Border.all(color: isDark ? const Color(0xFF222F4A) : Colors.grey.shade200), 
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: _staffEmerald.withValues(alpha: 0.15),
                                        child: Text(name.isNotEmpty ? name[0] : 'أ', style: IconTheme.of(context).color == Colors.white ? const TextStyle(color: Colors.white) : TextStyle(color: _staffEmerald, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                                                if (title.isNotEmpty) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                    decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                                    child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                                                  )
                                                ]
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(spec.isNotEmpty ? spec : 'تخصص غير محدد', style: TextStyle(fontSize: 12, color: mutedColor)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15))),

                                  // Actionable Contact Chips
                                  Wrap(
                                    spacing: 8, runSpacing: 8,
                                    children: [
                                      if (email.isNotEmpty)
                                        _buildContactChip(Icons.email_outlined, email, () => _copyToClipboard(email, 'البريد'), isDark, textColor, mutedColor),
                                      if (phone.isNotEmpty)
                                        _buildContactChip(Icons.phone_outlined, phone, () => _copyToClipboard(phone, 'الهاتف'), isDark, textColor, mutedColor),
                                      if (office.isNotEmpty)
                                        _buildContactChip(Icons.domain_verification_rounded, office, null, isDark, textColor, mutedColor),
                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      InkWell(onTap: () => _openStaffModal(s), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_rounded, size: 17, color: Colors.blue))),
                                      const SizedBox(width: 12),
                                      InkWell(onTap: () => _confirmAndDeleteStaff(id, name), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline_rounded, size: 17, color: Colors.redAccent))),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openStaffModal(),
        backgroundColor: _staffEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: const Text('إضافة أستاذ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildContactChip(IconData icon, String text, VoidCallback? onTap, bool isDark, Color textColor, Color mutedColor) {
    final chipBg = isDark ? Colors.white10 : const Color(0xFFF8FAFC);
    final chipBorder = isDark ? const Color(0xFF222F4A) : Colors.grey.shade200;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: chipBorder)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: onTap != null ? _staffEmerald : mutedColor),
              const SizedBox(width: 6),
              Text(text, style: TextStyle(fontSize: 11, color: onTap != null ? textColor : mutedColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_searchQuery.isEmpty ? Icons.group_off_rounded : Icons.search_off_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty ? 'لا يوجد أعضاء هيئة تدريس مسجلين' : 'لا يوجد أستاذ يطابق "$_searchQuery"',
            style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}