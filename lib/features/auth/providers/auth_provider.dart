import 'package:flutter/material.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  UserModel? _user;
  bool _isLoading = false;
  bool _isDisposed = false; // <--- درع حماية ضد كراش الخروج السريع

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  // --- Role Helpers (معقمة تماماً ضد مسافات الكيبورد وحالة الأحرف) ---
  bool get isAdmin => _user?.role?.trim().toLowerCase() == 'admin';
  bool get isStudent => _user?.role?.trim().toLowerCase() == 'student';
  bool get isStaff {
    final r = _user?.role?.trim().toLowerCase();
    return r == 'staff' || r == 'instructor' || r == 'teacher';
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // المُرسل الآمن للتحديثات
  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  // --- 1. مضاد الزهايمر (Auto-Session Recovery) ---
  Future<void> initializeAuth() async {
    _isLoading = true;
    
    try {
      final currentUid = _service.getCurrentUserId(); 
      if (currentUid != null) {
        final profile = await _service.getProfile(currentUid);
        _user = profile;
      } else {
        _user = null;
      }
    } catch (e) {
      // في حال انقطاع الإنترنت أثناء فتح التطبيق، اعتبره مسجلاً للخروج مؤقتاً
      _user = null; 
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  // --- 2. تسجيل الدخول ---
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _safeNotify();

    try {
      // استخدام .trim() لفلترة المسافات الوهمية من كيبورد الجوال
      final cleanEmail = email.trim();
      
      final response = await _service.signIn(cleanEmail, password);
      final uid = response.user?.id;
      
      if (uid == null) {
        throw Exception('فشل الحصول على معرّف الجلسة الخاصة بك من الخادم');
      }

      final profile = await _service.getProfile(uid);
      _user = profile;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  // --- 3. إنعاش البروفايل بالخلفية (صامت تماماً) ---
  Future<void> reloadProfile() async {
    if (_user == null) return;
    try {
      final updatedProfile = await _service.getProfile(_user!.id);
      _user = updatedProfile;
      _safeNotify();
    } catch (_) {
      // التجاهل الصامت كي لا نزعج المستخدم بإشعارات خطأ عابرة
    }
  }

  // --- 4. تسجيل الخروج الفولاذي ---
  Future<void> logout() async {
    _isLoading = true;
    _safeNotify();
    try {
      await _service.signOut();
    } catch (_) {
      // حتى لو فشل الاتصال بخادم Supabase، قم بتنظيف الذاكرة محلياً واطرده!
    } finally {
      _user = null;
      _isLoading = false;
      _safeNotify();
    }
  }
}