import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await Supabase.initialize(
    url: 'https://zzbgyqomlgiopzdouubx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6Ymd5cW9tbGdpb3B6ZG91dWJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxNzc4MDcsImV4cCI6MjA5Mjc1MzgwN30.bs3YDb9v7gF6d00dsvWKKcxrP3i6UcBh0j6hHvzDdXc',
  );
  runApp(const EsuyoApp());
}

class EsuyoApp extends StatelessWidget {
  const EsuyoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'E-Suyo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
