import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'core/di.dart';
import 'data/repositories/scan_history_repository_impl.dart';
import 'data/services/local_storage_service.dart';
import 'domain/repositories/scan_history_repository.dart';
import 'ui/core/theme.dart';
import 'ui/features/onboarding/views/onboarding_screen.dart';

import 'data/repositories/update_repository_impl.dart';
import 'data/services/app_info_service.dart';
import 'data/services/github_update_service.dart';
import 'domain/repositories/update_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _setupDependencies();
  runApp(const BarcodeScannerApp());
}

void _setupDependencies() {
  final storageService = LocalStorageService();
  final historyRepository = ScanHistoryRepositoryImpl(storageService: storageService);

  final updateService = GitHubUpdateService();
  final updateRepository = UpdateRepositoryImpl(service: updateService);
  final appInfoService = AppInfoService();

  di().register<LocalStorageService>(storageService);
  di().register<ScanHistoryRepository>(historyRepository);
  di().register<GitHubUpdateService>(updateService);
  di().register<UpdateRepository>(updateRepository);
  di().register<AppInfoService>(appInfoService);
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
