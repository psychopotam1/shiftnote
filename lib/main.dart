import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'l10n/generated/app_localizations.dart';
import 'locale_controller.dart';
import 'screens/month_screen.dart';
import 'services/pro_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const ShiftNoteApp());
}

class ShiftNoteApp extends StatefulWidget {
  const ShiftNoteApp({super.key});

  @override
  State<ShiftNoteApp> createState() => _ShiftNoteAppState();
}

class _ShiftNoteAppState extends State<ShiftNoteApp> {
  final LocaleController _localeController = LocaleController();
  final ProService _proService = ProService();

  @override
  void initState() {
    super.initState();
    _localeController.addListener(_handleLocaleChanged);
    _localeController.load();
    _proService.initPurchaseListener();
    _proService.checkPastPurchases();
  }

  @override
  void dispose() {
    _localeController.removeListener(_handleLocaleChanged);
    _localeController.dispose();
    _proService.dispose();
    super.dispose();
  }

  void _handleLocaleChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _localeController.locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('uk'),
        Locale('ru'),
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E13),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8EA3FF),
          secondary: Color(0xFFFFC264),
          surface: Color(0xFF141922),
        ),
        useMaterial3: true,
      ),
      home: MonthScreen(localeController: _localeController),
    );
  }
}