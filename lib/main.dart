import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'core/di.dart';
import 'data/repositories/scan_history_repository_impl.dart';
import 'data/services/local_storage_service.dart';
import 'domain/repositories/scan_history_repository.dart';
import 'ui/core/theme.dart';
import 'ui/features/onboarding/views/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _setupDependencies();
  runApp(const BarcodeScannerApp());
}

void _setupDependencies() {
  final storageService = LocalStorageService();
  final historyRepository = ScanHistoryRepositoryImpl(storageService: storageService);

  di().register<LocalStorageService>(storageService);
  di().register<ScanHistoryRepository>(historyRepository);
}

class BarcodeScannerApp extends StatelessWidget {
  const BarcodeScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Barcode Scanner',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const OnboardingScreen(),
        );
      },
    );
  }
}
