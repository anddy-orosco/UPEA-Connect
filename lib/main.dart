import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar idioma español para las fechas del calendario
  await initializeDateFormatting('es_ES', null);

  // Inicializar servicio de notificaciones locales
  await NotificationService().initNotification();

  // Verificar sesión persistida
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  // Cargar el tema guardado (o UPEA por defecto si no hay ninguno)
  final themeService = ThemeService();
  await themeService.loadTheme();

  runApp(MyApp(isLoggedIn: isLoggedIn, themeService: themeService));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final ThemeService themeService;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: themeService,
      child: Consumer<ThemeService>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'App Universitaria',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es', 'ES'),
            ],
            theme: theme.themeData,
            home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}