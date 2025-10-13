import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/qna_provider.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/connectivity_service.dart';
import 'widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await DatabaseService.init();
  await ConnectivityService().initialize();
  
  runApp(const EdumateApp());
}

class EdumateApp extends StatelessWidget {
  const EdumateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => QNAProvider(),
      child: MaterialApp(
        title: 'Edumate',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0F0F0F),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F0F0F),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}