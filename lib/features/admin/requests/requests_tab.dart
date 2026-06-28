import 'package:flutter/material.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart'; // <--- مخزن الألوان الرسمي للمعهد

class AdminRequestsTab extends StatefulWidget {
  const AdminRequestsTab({super.key});

  @override
  State<AdminRequestsTab> createState() => _AdminRequestsTabState();
}

class _AdminRequestsTabState extends State<AdminRequestsTab> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _selectedFilter = 'الكل'; 

  final List<String> _filters = ['الكل', 'جديد', 'قيد المراجعة', 'منجز', 'مرفوض'];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getAllRequests();
      if (mounted) setState(() => _requests = data);
    } catch (e) {
      if (mounted) _showSnackBar('خطأ في تحميل الطلبات: $e', isError: true);
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

  // --- دالة الألوان المربوطة بالـ Design System ---
  ({Color color, IconData icon}) _getStatusMeta(String status) {
    switch (status) {
      case 'منجز': return (color: AppColors.success, icon: Icons.check_circle_rounded); 
      case 'مرفوض': return (color: AppColors.danger, icon: Icons.cancel_rounded); 
      case 'قيد المراجعة': return (color: AppColors.warning, icon: Icons.hourglass_top_rounded); 
      case 'جديد': default: return (color: AppColors.primary, icon: Icons.mark_email_unread_rounded); 
    }
  }

  // --- البوتوم شيت التفاعلي (مجهّز للدارك واللايت معاً) ---
  void _openUpdateRequestModal(Map<String, dynamic> request) {
    String currentStatus = request['status'] ?? 'جديد';
    final noteController = TextEditingController(text: request['admin_note'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder( 
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
          final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 20, right: 20, top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('اتخاذ إجراء على الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 4),
                Text('مقدم الطلب: ${request['profiles']?['name'] ?? 'طالب'}', style: TextStyle(fontSize: 13, color: mutedColor)),
                const SizedBox(height: 20),

                Text('تغيير حالة الطلب إلى:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ['جديد', 'قيد المراجعة', 'منجز', 'مرفوض'].map((st) {
                    final isSelected = currentStatus == st;
                    final meta = _getStatusMeta(st);
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setModalState(() => currentStatus = st),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? meta.color : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? meta.color : Colors.grey.withValues(alpha: 0.2), width: 1.5),
                          boxShadow: isSelected ? [BoxShadow(color: meta.color.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(meta.icon, size: 16, color: isSelected ? Colors.white : meta.color),
                            const SizedBox(width: 6),
                            Text(st, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : textColor)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),
                TextFormField(
                  controller: noteController,
                  maxLines: 3,
                  style: TextStyle(fontSize: 13, color: textColor),
                  decoration: InputDecoration(
                    labelText: 'ملاحظة إدارية للطالب (اختياري)',
                    labelStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 12),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF131C2E) : Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: () async {
                      final targetId = request['id'];
                      final noteText = noteController.text.trim();
                      
                      Navigator.pop(context);
                      try {
                        await _supabaseService.updateRequestStatus(
                          targetId,
                          currentStatus,
                          noteText.isEmpty ? null : noteText,
                        );
                        if (mounted) {
                          _loadRequests();
                          _showSnackBar('تم تحديث حالة الطلب بنجاح');
                        }
                      } catch (e) {
                        if (mounted) _showSnackBar('حدث خطأ أثناء التحديث: $e', isError: true);
                      }
                    },
                    child: const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final filteredList = _selectedFilter == 'الكل' 
        ? _requests 
        : _requests.where((r) => (r['status'] ?? 'جديد') == _selectedFilter).toList();

    return Scaffold(
      body: Column(
        children: [
          // --- Top Filter Bar (بديل مصفّح ضد الـ Overflow) ---
          Container(
            height: 66, width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface, 
              border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filterName = _filters[index];
                final isSelected = _selectedFilter == filterName;
                final count = filterName == 'الكل' ? _requests.length : _requests.where((r) => (r['status'] ?? 'جديد') == filterName).length;

                return _buildObsidianChip(filterName, count, isSelected, isDark);
              },
            ),
          ),

          // --- Requests List ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredList.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadRequests,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final r = filteredList[index];
                            final studentName = r['profiles']?['name'] ?? 'طالب غير مدرج';
                            final type = r['type'] ?? 'طلب عام';
                            final details = r['details'] ?? 'لا توجد تفاصيل إضافية';
                            final status = r['status'] ?? 'جديد';
                            final adminNote = r['admin_note'] ?? '';
                            final rawDate = r['created_at']?.toString() ?? '';
                            final dateStr = rawDate.length >= 10 ? rawDate.substring(0, 10) : '';

                            final meta = _getStatusMeta(status);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isDark ? const Color(0xFF222F4A) : Colors.grey.shade200)),
                              color: isDark ? const Color(0xFF131C2E) : Colors.white,
                              elevation: 0,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _openUpdateRequestModal(r),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                                child: Text(studentName.isNotEmpty ? studentName[0] : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                              ),
                                              const SizedBox(width: 10),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(studentName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                                                  Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.lightTextMuted)),
                                                ],
                                              )
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: meta.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: meta.color.withValues(alpha: 0.3))),
                                            child: Row(
                                              children: [
                                                Icon(meta.icon, size: 12, color: meta.color),
                                                const SizedBox(width: 4),
                                                Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: meta.color)),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),

                                      const SizedBox(height: 14),
                                      Text(type, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                                      const SizedBox(height: 4),
                                      Text(details, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B), height: 1.4)),

                                      if (adminNote.isNotEmpty) ...[
                                        const SizedBox(height: 14),
                                        Container(
                                          width: double.infinity, padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning.withValues(alpha: 0.1),
                                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                                            border: const Border(right: BorderSide(color: AppColors.warning, width: 3)), 
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.reply_rounded, size: 14, color: AppColors.warning),
                                                  SizedBox(width: 4),
                                                  Text('رد الإدارة:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning)),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(adminNote, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFFBBF24) : Colors.amber.shade900, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        )
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // --- ويدجت الكبسولة الملكية المصفّحة ضد الـ Overflow ---
  Widget _buildObsidianChip(String title, int count, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF131C2E) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.15)),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)))),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: isSelected ? Colors.white.withValues(alpha: 0.25) : (isDark ? Colors.white12 : Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)))),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(
            _selectedFilter == 'الكل' ? 'لا توجد طلبات مقدمة حتى الآن' : 'لا توجد طلبات في قسم ($_selectedFilter)',
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}