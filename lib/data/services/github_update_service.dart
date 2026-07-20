import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class GitHubReleaseAsset {
  final String name;
  final String downloadUrl;
  final int size;

  GitHubReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  factory GitHubReleaseAsset.fromJson(Map<String, dynamic> json) {
    return GitHubReleaseAsset(
      name: json['name'] as String? ?? '',
      downloadUrl: json['browser_download_url'] as String? ?? '',
      size: json['size'] as int? ?? 0,
    );
  }
}

class GitHubReleaseData {
  final String tagName;
  final String htmlUrl;
  final String? body;
  final String? apkUrl;
  final int? apkSize;
  final String? sha1Url;

  GitHubReleaseData({
    required this.tagName,
    required this.htmlUrl,
    this.body,
    this.apkUrl,
    this.apkSize,
    this.sha1Url,
  });

  factory GitHubReleaseData.fromJson(Map<String, dynamic> json) {
    String? apkUrl;
    int? apkSize;
    String? sha1Url;

    if (json['assets'] is List) {
      final assetsList = (json['assets'] as List)
          .map((a) => GitHubReleaseAsset.fromJson(a as Map<String, dynamic>))
          .toList();

      for (final asset in assetsList) {
        final lowerName = asset.name.toLowerCase();
        if (lowerName.endsWith('.apk.sha1') || lowerName.endsWith('.sha1')) {
          sha1Url = asset.downloadUrl;
        } else if (lowerName.endsWith('.apk')) {
          apkUrl = asset.downloadUrl;
          apkSize = asset.size;
        }
      }
    }

    return GitHubReleaseData(
      tagName: json['tag_name'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? AppConstants.githubRepoUrl,
      body: json['body'] as String?,
      apkUrl: apkUrl,
      apkSize: apkSize,
      sha1Url: sha1Url,
    );
  }
}

class GitHubUpdateService {
  Future<GitHubReleaseData?> fetchLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.githubLatestReleaseApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': AppConstants.httpUserAgent,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return GitHubReleaseData.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('GitHub API returned status code ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
