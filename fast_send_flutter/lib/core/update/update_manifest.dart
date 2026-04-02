class UpdateManifest {
  final String latestVersion;
  final String? windowsDownloadUrl;
  final String? macDownloadUrl;
  final String? releaseNotes;
  final String? releasePageUrl;

  const UpdateManifest({
    required this.latestVersion,
    this.windowsDownloadUrl,
    this.macDownloadUrl,
    this.releaseNotes,
    this.releasePageUrl,
  });

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    return UpdateManifest(
      latestVersion: (json['latestVersion'] as String?)?.trim() ?? '',
      windowsDownloadUrl: (json['windowsDownloadUrl'] as String?)?.trim(),
      macDownloadUrl: (json['macDownloadUrl'] as String?)?.trim(),
      releaseNotes: (json['releaseNotes'] as String?)?.trim(),
      releasePageUrl: (json['releasePageUrl'] as String?)?.trim(),
    );
  }
}

