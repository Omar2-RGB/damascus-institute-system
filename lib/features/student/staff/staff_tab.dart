import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../../../../data/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart'; // <--- استوردنا الألوان السيادية

class StudentStaffTab extends StatefulWidget {
  const StudentStaffTab({super.key});

  @override
  State<StudentStaffTab> createState() => _StudentStaffTabState();
}

class _StudentStaffTabState extends State<StudentStaffTab> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _staff = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadStaff());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getStaff();
      if (mounted) setState(() => _staff = data);
    } catch (e) {
      if (mounted) _showSnackBar('خطأ في جلب بيانات الهيئة التدريسية', isError: true);
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyEmail(String? email, String profName) {
    if (email == null || email.isEmpty) return;
    Clipboard.setData(ClipboardData(text: email));
    _showSnackBar('تم نسخ بريد $profName 📧');
  }

  String _getCleanInitial(String name) {
    final clean = name.replaceAll(RegExp(r'^(د\.|م\.|أ\.|الدكتور|المهندس|الأستاذ)\s*'), '');
    return clean.isNotEmpty ? clean[0] : 'أ';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final filteredList = _searchQuery.isEmpty
        ? _staff
        : _staff.where((s) {
            final name = (s['name'] ?? '').toLowerCase();
            final title = (s['title'] ?? '').toLowerCase();
            final spec = (s['specialization'] ?? '').toLowerCase(); 
            final q = _searchQuery.toLowerCase();
            return name.contains(q) || title.contains(q) || spec.contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent, // لأخذ خلفية الـ IndexedStack
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. Top Header & Live Search ---
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface, 
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))], 
                border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15)))
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
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                        child: Text('${_staff.length} مدرّس', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search field
                  TextFormField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(fontSize: 13, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن دكتور، أستاذ، أو تخصص...',
                      hintStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
                      suffixIcon: _searchQuery.isEmpty ? null : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                      filled: true, fillColor: isDark ? const Color(0xFF131C2E) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. Staff Directory Cards ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : filteredList.isEmpty
                      ? _buildEmptyState(isDark)
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _loadStaff,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final s = filteredList[index];
                              final rawName = s['name'] ?? 'أستاذ غير مسمى';
                              final title = s['title'] ?? '';
                              final email = s['email'] ?? '';
                              final office = s['office_hours'] ?? '';
                              final spec = s['specialization'] ?? ''; 

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF131C2E) : Colors.white, 
                                  borderRadius: BorderRadius.circular(20), 
                                  border: Border.all(color: isDark ? const Color(0xFF222F4A) : Colors.grey.shade100), 
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.015), blurRadius: 10, offset: const Offset(0, 2))]
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Avatar + Name + Scientific Title
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                          child: Text(_getCleanInitial(rawName), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(rawName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                                                  if (title.isNotEmpty) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                                      child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                    )
                                                  ]
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(spec.isNotEmpty ? spec : 'عضو هيئة تدريس', style: TextStyle(fontSize: 12, color: mutedColor)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15))),

                                    // Row 2: Office Hours (Left) + Copy Email Button (Right)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Office info
                                        Row(
                                          children: [
                                            Icon(Icons.access_time_rounded, size: 14, color: mutedColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              office.isNotEmpty ? office : 'الساعات غير معلنة', 
                                              style: TextStyle(fontSize: 11, color: mutedColor, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),

                                        // Copy Button
                                        if (email.isNotEmpty)
                                          InkWell(
                                            borderRadius: BorderRadius.circular(10),
                                            onTap: () => _copyEmail(email, rawName),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.mark_email_read_rounded, size: 14, color: AppColors.primary),
                                                  SizedBox(width: 4),
                                                  Text('نسخ البريد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                ],
                                              ),
                                            ),
                                          )
                                        else
                                          const Text('لا يوجد بريد', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_searchQuery.isEmpty ? Icons.school_outlined : Icons.search_off_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty ? 'لا يوجد أساتذة مدرجين في السجل' : 'لا يوجد أستاذ يطابق "$_searchQuery"',
            style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}