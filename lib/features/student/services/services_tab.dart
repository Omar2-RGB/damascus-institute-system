import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';

class StudentServicesTab extends StatefulWidget {
  const StudentServicesTab({super.key});

  @override
  State<StudentServicesTab> createState() => _StudentServicesTabState();
}

class _StudentServicesTabState extends State<StudentServicesTab> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().user;
    if (user != null && _userId == null) {
      _userId = user.id;
      _loadRequests();
    }
  }

  Future<void> _loadRequests() async {
    if (_userId == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getRequests(_userId!);
      if (mounted) setState(() => _requests = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNewRequestDialog() {
    final typeController = TextEditingController();
    final detailsController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تقديم طلب جديد'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: typeController,
                decoration: const InputDecoration(labelText: 'نوع الطلب (مثلاً: إفادة)'),
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'التفاصيل'),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                try {
                  final user = context.read<AuthProvider>().user;
                  if (user == null) return;
                  await _supabaseService.createRequest({
                    'student_id': user.id,
                    'type': typeController.text,
                    'details': detailsController.text,
                    'status': 'جديد',
                  });
                  await _loadRequests();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تقديم الطلب بنجاح')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('تقديم'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: _requests.isEmpty
          ? const Center(child: Text('لا توجد طلبات سابقة.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final r = _requests[index];
                final type = r['type'] ?? '';
                final status = r['status'] ?? '';
                final details = r['details'] ?? '';
                final note = r['admin_note'] ?? '';

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(type),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الحالة: $status'),
                        if (details.isNotEmpty) Text('التفاصيل: $details'),
                        if (note.isNotEmpty) Text('ملاحظة الإدارة: $note', style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewRequestDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}