import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart'; // <--- استوردنا مخزن الألوان الموحّد

class AdminAnnouncementsTab extends StatefulWidget {
  const AdminAnnouncementsTab({super.key});

  @override
  State<AdminAnnouncementsTab> createState() => _AdminAnnouncementsTabState();
}

class _AdminAnnouncementsTabState extends State<AdminAnnouncementsTab> {
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
      if (mounted) _showSnackBar('خطأ في تحميل الإعلانات: $e', isError: true);
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
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // --- دايالوغ الحذف الفخم (مجهز للدارك واللايت) ---
  Future<void> _deleteAnnouncement(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
        final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

        return Dialog(
          backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: isDark ? const Color(0xFF222F4A) : Colors.transparent)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 36),
                ),
                const SizedBox(height: 16),
                Text('تأكيد الحذف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text(
                  'هل أنت متأكد من رغبتك في حذف هذا الإعلان؟ لا يمكن التراجع عن هذه الخطوة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedColor, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('إلغاء', style: TextStyle(color: mutedColor, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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

    if (confirm != true) return;

    try {
      await _supabaseService.deleteAnnouncement(id);
      await _loadAnnouncements();
      if (mounted) _showSnackBar('تم حذف الإعلان بنجاح');
    } catch (e) {
      if (mounted) _showSnackBar('خطأ في الحذف: $e', isError: true);
    }
  }

  // --- Bottom Sheet موحّد (للإضافة والتعديل معاً) ---
  void _openAnnouncementModal([Map<String, dynamic>? existingAnnouncement]) {
    final isEditing = existingAnnouncement != null;
    final titleController = TextEditingController(text: isEditing ? existingAnnouncement['title'] : '');
    final bodyController = TextEditingController(text: isEditing ? existingAnnouncement['body'] : '');
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 20, right: 20, top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 20),
                Text(
                  isEditing ? 'تعديل الإعلان' : 'نشر إعلان جديد',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 20),
                _buildCustomTextField(controller: titleController, label: 'عنوان الإعلان *', icon: Icons.title_rounded, isDark: isDark),
                const SizedBox(height: 16),
                _buildCustomTextField(controller: bodyController, label: 'محتوى الإعلان *', icon: Icons.notes_rounded, maxLines: 4, isDark: isDark),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(context);

                      try {
                        if (isEditing) {
                          await _supabaseService.updateAnnouncement(existingAnnouncement['id'], {
                            'title': titleController.text.trim(),
                            'body': bodyController.text.trim(),
                          });
                          if (mounted) _showSnackBar('تم تحديث الإعلان');
                        } else {
                          await _supabaseService.createAnnouncement(
                            title: titleController.text.trim(),
                            body: bodyController.text.trim(),
                            publishedBy: context.read<AuthProvider>().user!.id,
                          );
                          if (mounted) _showSnackBar('تم نشر الإعلان بنجاح');
                        }
                        await _loadAnnouncements();
                      } catch (e) {
                        if (mounted) _showSnackBar('حدث خطأ: $e', isError: true);
                      }
                    },
                    child: Text(isEditing ? 'حفظ التعديلات' : 'نشر الآن', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1, required bool isDark}) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final fillColor = isDark ? const Color(0xFF131C2E) : const Color(0xFFF8FAFC);

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 13),
        alignLabelWithHint: maxLines > 1,
        prefixIcon: maxLines == 1 ? Icon(icon, color: AppColors.lightTextMuted, size: 20) : null,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // --- Top Statistics Banner ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('لوحة الإعلانات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 2),
                          Text('إجمالي المنشورات: ${_announcements.length}', style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          children: [
                            Icon(Icons.podcasts_rounded, size: 14, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text('مباشر', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // --- Announcements List ---
                Expanded(
                  child: _announcements.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.25)),
                              const SizedBox(height: 12),
                              Text('لا توجد إعلانات منشورة بعد', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _loadAnnouncements,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: _announcements.length,
                            itemBuilder: (context, index) => _AnnouncementCard(
                              announcement: _announcements[index],
                              onEdit: () => _openAnnouncementModal(_announcements[index]),
                              onDelete: () => _deleteAnnouncement(_announcements[index]['id'] ?? ''),
                              isDark: isDark,
                            ),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAnnouncementModal(),
        backgroundColor: const Color(0xFFFF6D00), // Orange Accent
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_alert_rounded, size: 20),
        label: const Text('إعلان جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}

// --- ويدجت الكرت المستقلة (Cinematic Card) ---
class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> announcement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDark;

  const _AnnouncementCard({required this.announcement, required this.onEdit, required this.onDelete, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final title = announcement['title'] ?? '';
    final body = announcement['body'] ?? '';
    final date = announcement['created_at']?.toString().substring(0, 10) ?? '';
    
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final cardBg = isDark ? const Color(0xFF131C2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF222F4A) : Colors.grey.shade100;
    final dividerColor = isDark ? Colors.white10 : const Color(0xFFF8FAFC);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: Color(0xFFFF6D00), width: 4)), // الحافة البرتقالية الرهيبة
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date & Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.lightTextMuted),
                        const SizedBox(width: 6),
                        Text(date, style: const TextStyle(fontSize: 11, color: AppColors.lightTextMuted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Icon(Icons.push_pin_rounded, size: 14, color: Color(0xFFFF6D00)),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 6),
              // Body
              Text(body, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B), height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
              
              Divider(height: 24, color: dividerColor),
              
              // Actions (Edit / Delete)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('تعديل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    icon: const Icon(Icons.delete_rounded, size: 16),
                    label: const Text('حذف', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: onDelete,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}