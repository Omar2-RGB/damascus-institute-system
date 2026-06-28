import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SupabaseService {
  final _auth = Supabase.instance.client.auth;
  final _db = Supabase.instance.client;

  // ==================== الأساسيات والمصادقة ====================
  Future<AuthResponse> signIn(String email, String password) async {
    return await _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.id;
  }

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getProfile(String uid) async {
    final data = await _db
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  Future<void> createProfile(UserModel user) async {
    await _db.from('profiles').insert(user.toMap());
  }

  // ==================== إدارة الطلاب ====================
  Future<List<UserModel>> getAllStudents() async {
    final data = await _db
        .from('profiles')
        .select()
        .neq('role', 'admin')
        .order('name');
    return data.map<UserModel>((e) => UserModel.fromMap(e)).toList();
  }

  // --- ميزة جديدة: البحث السريع في الداتا بيز (لتحسين الأداء) ---
  Future<List<UserModel>> searchStudents(String query) async {
    final data = await _db
        .from('profiles')
        .select()
        .neq('role', 'admin')
        .or('name.ilike.%$query%,student_id.ilike.%$query%');
    return data.map<UserModel>((e) => UserModel.fromMap(e)).toList();
  }

  // --- ميزة جديدة: الاستيراد الجماعي (Bulk Import) للإكسل ---
  Future<void> bulkAddStudents(List<Map<String, dynamic>> students) async {
    await _db.from('profiles').insert(students);
  }

  Future<void> deleteStudent(String uid) async {
    await _db.from('profiles').delete().eq('id', uid);
  }

  Future<UserModel> addStudent({
    required String name,
    required String email,
    required String password,
    required String role,
    String? studentId,
    String? department,
    int? year,
  }) async {
    final response = await _auth.signUp(email: email, password: password);
    if (response.user == null) {
      throw Exception('فشل إنشاء الحساب');
    }
    final uid = response.user!.id;
    final profile = UserModel(
      id: uid,
      name: name,
      email: email,
      role: role,
      studentId: studentId,
      department: department,
      year: year,
    );
    await createProfile(profile);
    return profile;
  }

  Future<void> updateStudent(String uid, Map<String, dynamic> data) async {
    await _db.from('profiles').update(data).eq('id', uid);
  }
// --- توليد حسابات للطلاب الذين تم استيرادهم من الإكسل ---
// --- توليد حسابات للطلاب الذين تم استيرادهم من الإكسل ---
  Future<String> generateStudentAccounts() async {
    final response = await _db.rpc('generate_student_accounts');
    return response.toString();
  }
  // ==================== الإعلانات ====================
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final data = await _db
        .from('announcements')
        .select()
        .order('created_at', ascending: false);
    return data;
  }

  Future<void> createAnnouncement({
    required String title,
    required String body,
    String? imageUrl,
    required String publishedBy,
  }) async {
    await _db.from('announcements').insert({
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'published_by': publishedBy,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> updateAnnouncement(String id, Map<String, dynamic> data) async {
    await _db.from('announcements').update(data).eq('id', id);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.from('announcements').delete().eq('id', id);
  }

  // ==================== الأساتذة ====================
  Future<List<Map<String, dynamic>>> getStaff() async {
    final data = await _db.from('staff').select().order('name');
    return data;
  }

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    final data = await _db.from('staff').select().order('name');
    return data;
  }

  Future<void> addStaff({
    required String name,
    String? title,
    String? email,
    String? phone,
    String? specialization,
    String? officeHours,
  }) async {
    await _db.from('staff').insert({
      'name': name,
      'title': title,
      'email': email,
      'phone': phone,
      'specialization': specialization,
      'office_hours': officeHours,
    });
  }

  Future<void> updateStaff(String id, Map<String, dynamic> data) async {
    await _db.from('staff').update(data).eq('id', id);
  }

  Future<void> deleteStaff(String id) async {
    await _db.from('staff').delete().eq('id', id);
  }

  // ==================== العلامات ====================
  Future<List<Map<String, dynamic>>> getGrades(String studentId) async {
    final data = await _db
        .from('grades')
        .select()
        .eq('student_id', studentId)
        .order('semester');
    return data;
  }

  Future<void> addGrade({
    required String studentId,
    required String subject,
    required String semester,
    required double grade,
    double maxGrade = 100,
    String? note,
  }) async {
    await _db.from('grades').insert({
      'student_id': studentId,
      'subject': subject,
      'semester': semester,
      'grade': grade,
      'max_grade': maxGrade,
      'note': note,
    });
  }

  Future<void> updateGrade(String id, Map<String, dynamic> data) async {
    await _db.from('grades').update(data).eq('id', id);
  }

  Future<void> deleteGrade(String id) async {
    await _db.from('grades').delete().eq('id', id);
  }
// --- ميزة الاستيراد الجماعي للعلامات ---
  Future<void> bulkAddGrades(List<Map<String, dynamic>> gradesList) async {
    await _db.from('grades').insert(gradesList);
  }
  // ==================== الحضور والغياب ====================
  Future<List<Map<String, dynamic>>> getAllAttendance() async {
    final data = await _db
        .from('attendance')
        .select('*, profiles!inner(name), schedules!inner(subject, start_time, end_time)')
        .order('date', ascending: false);
    return data;
  }

  Future<List<Map<String, dynamic>>> getAttendance(String studentId) async {
    final data = await _db
        .from('attendance')
        .select('*, schedules(subject, start_time, end_time)')
        .eq('student_id', studentId)
        .order('date');
    return data;
  }

  Future<List<Map<String, dynamic>>> getStudentAttendance(String studentId) async {
    final data = await _db
        .from('attendance')
        .select('*, schedules(subject, start_time, end_time)')
        .eq('student_id', studentId)
        .order('date', ascending: false);
    return data;
  }

  Future<List<Map<String, dynamic>>> getGroupSchedules(String groupId) async {
    final data = await _db
        .from('schedules')
        .select('*')
        .eq('group_id', groupId)
        .order('day_of_week')
        .order('start_time');
    return data;
  }

  Future<void> addAttendanceRecord({
    required String studentId,
    required String scheduleId,
    required String date,
    required String status,
    String? note,
  }) async {
    await _db.from('attendance').insert({
      'student_id': studentId,
      'schedule_id': scheduleId,
      'date': date,
      'status': status,
      'note': note,
    });
  }

  Future<void> updateAttendanceRecord(String id, Map<String, dynamic> data) async {
    await _db.from('attendance').update(data).eq('id', id);
  }

  Future<void> deleteAttendanceRecord(String id) async {
    await _db.from('attendance').delete().eq('id', id);
  }

  // ==================== الخدمات (الطلبات) ====================
  Future<List<Map<String, dynamic>>> getRequests(String studentId) async {
    final data = await _db
        .from('requests')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    return data;
  }

  Future<void> createRequest(Map<String, dynamic> request) async {
    await _db.from('requests').insert(request);
  }

  Future<List<Map<String, dynamic>>> getAllRequests() async {
    final data = await _db
        .from('requests')
        .select('*, profiles(name)')
        .order('created_at', ascending: false);
    return data;
  }

  Future<void> updateRequestStatus(String requestId, String newStatus, String? adminNote) async {
    await _db
        .from('requests')
        .update({'status': newStatus, 'admin_note': adminNote})
        .eq('id', requestId);
  }

  // ==================== إدارة المجموعات ====================
  Future<List<Map<String, dynamic>>> getAllGroups() async {
    final data = await _db.from('groups').select().order('name');
    return data;
  }

  Future<void> createGroup(String name, String? department, int? year) async {
    await _db.from('groups').insert({
      'name': name,
      'department': department,
      'year': year,
    });
  }

  Future<void> updateGroup(String id, Map<String, dynamic> data) async {
    await _db.from('groups').update(data).eq('id', id);
  }

// ==================== الجداول الدراسية (النظام الجديد) ====================

  // 1. جلب الجدول بناءً على التخصص والسنة والفصل
  Future<List<Map<String, dynamic>>> getScheduleByFilters(String dept, String year, String semester) async {
    return await _db.from('schedules')
        .select('*, staff:instructor_id(name)')
        .eq('department', dept)
        .eq('year', year)
        .eq('semester', semester)
        .order('start_time', ascending: true);
  }

  // 2. إضافة محاضرة للجدول الثابت
  Future<void> addScheduleEntry({
    required String department,
    required String year,
    required String semester,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    required String subject,
    String? room,
    String? instructorId,
  }) async {
    await _db.from('schedules').insert({
      'department': department,
      'year': year,
      'semester': semester,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'subject': subject,
      'room': room,
      'instructor_id': instructorId,
    });
  }
  Future<void> updateScheduleEntry(String id, Map<String, dynamic> data) async {
    await _db.from('schedules').update(data).eq('id', id);
  }

  Future<void> deleteScheduleEntry(String id) async {
    await _db.from('schedules').delete().eq('id', id);
  }

  // ==================== لوحة المعلومات الإحصائية ====================
  Future<Map<String, int>> getDashboardCounts() async {
    final studentsCount = await _db.from('profiles').select().neq('role', 'admin').count(CountOption.exact);
    final staffCount = await _db.from('staff').select().count(CountOption.exact);
    final announcementsCount = await _db.from('announcements').select().count(CountOption.exact);
    final pendingRequests = await _db.from('requests').select().eq('status', 'جديد').count(CountOption.exact);
    
    return {
      'students': studentsCount.count ?? 0,
      'staff': staffCount.count ?? 0,
      'announcements': announcementsCount.count ?? 0,
      'pendingRequests': pendingRequests.count ?? 0,
    };
  }
}