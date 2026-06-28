import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart'; // <--- 1. استيراد الباشمهندس (Design System)

import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/admin/admin_home_screen.dart';
import 'features/student/student_home_screen.dart';

const Color _seedColor = Color(0xFF2563EB); 

class DamascusInstituteApp extends StatelessWidget {
  const DamascusInstituteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المعهد التقاني للحاسوب - درعا',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'SY')],
      locale: const Locale('ar', 'SY'),

      // ====================================================
      // 2. تفجير السحر هنا (حقن الديكور الجديد)
      // ====================================================
      themeMode: ThemeMode.dark, // <--- قفلناه "دارك إجباري" لتكحّل عينك فوراً!
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: _seedColor)));
          }
          if (!auth.isLoggedIn) return const LoginScreen();
          return auth.isAdmin ? const AdminHomeScreen() : const StudentHomeScreen();
        },
      ),
    );
  }
}