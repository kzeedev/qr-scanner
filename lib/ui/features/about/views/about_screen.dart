import 'package:flutter/material.dart';
import '../../../../core/di.dart';
import '../../../../domain/repositories/update_repository.dart';
import '../../onboarding/views/qr_scanner_graphic.dart';
import '../view_models/about_view_model.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final AboutViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AboutViewModel(
      updateRepository: di().get<UpdateRepository>(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              size: 32, color: Color(0xFFFFA726)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('About App'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final updateInfo = _viewModel.updateInfo;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFA726).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const QRScannerGraphic(size: 100),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bulk Barcode Scanner',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA726).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFA726).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'Version ${AboutViewModel.appVersion}',
                      style: TextStyle(
                        color: Color(0xFFFFA726),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Text(
                    AboutViewModel.appDescription,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // GitHub Page Tile
                Card(
                  elevation: 0,
                  color: const Color(0xFF222222),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.code_rounded,
                        color: Color(0xFFFFA726),
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'GitHub Repository',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: const Text(
                      'github.com/KZeeDev/qr-scanner',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    trailing: const Icon(
                      Icons.open_in_new_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onTap: () {
                      _viewModel.launchUrlString(AboutViewModel.githubUrl);
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Check for Updates Tile
                Card(
                  elevation: 0,
                  color: const Color(0xFF222222),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: updateInfo?.hasUpdate == true
                          ? const Color(0xFFFFA726)
                          : Colors.white10,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.system_update_rounded,
                                color: Color(0xFFFFA726),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Check for Updates',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getStatusSubtitle(updateInfo),
                                    style: TextStyle(
                                      color: updateInfo?.hasUpdate == true
                                          ? const Color(0xFFFFA726)
                                          : Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_viewModel.isChecking) ...[
                          const SizedBox(height: 16),
                          const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFFA726)),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _viewModel.checkForUpdates,
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: Text(
                                    updateInfo == null
                                        ? 'Check Now'
                                        : 'Check Again',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white24),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              if (updateInfo?.hasUpdate == true &&
                                  updateInfo?.releaseUrl != null) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      _viewModel.launchUrlString(
                                          updateInfo!.releaseUrl!);
                                    },
                                    icon: const Icon(Icons.download_rounded,
                                        size: 18),
                                    label: const Text('Download'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFA726),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'Created by KZeeDev • Open Source',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getStatusSubtitle(dynamic updateInfo) {
    if (_viewModel.isChecking) {
      return 'Checking GitHub releases...';
    }
    if (updateInfo == null) {
      return 'Check if a newer version is available.';
    }
    if (updateInfo.error != null) {
      return updateInfo.error;
    }
    if (updateInfo.hasUpdate) {
      return 'New version available: v${updateInfo.latestVersion}';
    }
    return 'You are using the latest version (${AboutViewModel.appVersion}).';
  }
}
