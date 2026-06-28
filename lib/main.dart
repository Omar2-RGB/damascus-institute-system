import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/auth/providers/auth_provider.dart'; // عدّل المسار حسب مشروعك

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تحميل المفاتيح من الخزنة السرية
  await dotenv.load(fileName: ".env");

  // 2. تشغيل محرك قاعدة البيانات بأمان
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 3. تجهيز "مضاد الزهايمر" وفحص الجلسة قبل بناء الـ UI
  final authProvider = AuthProvider();
  await authProvider.initializeAuth();

  // 4. إقلاع التطبيق مع حقن الـ Provider بالقمة (Root)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        // بكرة بس نعمل Provider للطالب أو الإشعارات بنحطه هون
      ],
      child: const DamascusInstituteApp(),
    ),
  );
}