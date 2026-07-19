import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubReleaseData {
  final String tagName;
  final String htmlUrl;
  final String? body;

  GitHubReleaseData({
    required this.tagName,
    required this.htmlUrl,
    this.body,
  });

  factory GitHubReleaseData.fromJson(Map<String, dynamic> json) {
    return GitHubReleaseData(
      tagName: json['tag_name'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? 'https://github.com/KZeeDev/qr-scanner',
      body: json['body'] as String?,
    );
  }
}

class GitHubUpdateService {
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/KZeeDev/qr-scanner/releases/latest';

  Future<GitHubReleaseData?> fetchLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse(_latestReleaseUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'BulkBarcodeScannerApp',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return GitHubReleaseData.fromJson(data);
      } else if (response.statusCode == 404) {
        // No release published yet
        return null;
      } else {
        throw Exception('GitHub API returned status code ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
