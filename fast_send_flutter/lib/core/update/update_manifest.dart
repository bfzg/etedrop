class UpdateManifest {
  final String latestVersion;
  final String? windowsVersion;
  final String? macVersion;
  final String? linuxVersion;
  final String? iosVersion;
  final String? androidVersion;
  final String? windowsDownloadUrl;
  final String? macDownloadUrl;
  final String? linuxDownloadUrl;
  final String? iosDownloadUrl;
  final String? androidDownloadUrl;
  /// Release notes by language code (e.g. "zh", "en").
  /// Each item is a single line, displayed as a list.
  final Map<String, List<String>> releaseNotes;
  final String? releasePageUrl;
  final bool forceUpdate;

  const UpdateManifest({
    required this.latestVersion,
    this.windowsVersion,
    this.macVersion,
    this.linuxVersion,
    this.iosVersion,
    this.androidVersion,
    this.windowsDownloadUrl,
    this.macDownloadUrl,
    this.linuxDownloadUrl,
    this.iosDownloadUrl,
    this.androidDownloadUrl,
    this.releaseNotes = const {},
    this.releasePageUrl,
    this.forceUpdate = false,
  });

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    final notesRaw = json['releaseNotes'];
    Map<String, List<String>> notes = const {};
    if (notesRaw is Map) {
      final out = <String, List<String>>{};
      for (final e in notesRaw.entries) {
        final key = (e.key ?? '').toString().trim().toLowerCase();
        final v = e.value;
        if (key.isEmpty) continue;
        if (v is List) {
          out[key] = v
              .map((it) => it?.toString().trim() ?? '')
              .where((s) => s.isNotEmpty)
              .toList(growable: false);
        } else if (v is String) {
          // Back-compat: allow a multi-line string.
          out[key] = v
              .split('\n')
              .map((it) => it.trim())
              .where((s) => s.isNotEmpty)
              .toList(growable: false);
        }
      }
      notes = out;
    } else if (notesRaw is String) {
      // Back-compat: treat as English text blob.
      notes = {
        'en': notesRaw
            .split('\n')
            .map((it) => it.trim())
            .where((s) => s.isNotEmpty)
            .toList(growable: false),
      };
    }

    String? pickStr(String key) {
      final s = (json[key] as String?)?.trim();
      if (s == null || s.isEmpty) return null;
      return s;
    }

    return UpdateManifest(
      latestVersion: (json['latestVersion'] as String?)?.trim() ?? '',
      windowsVersion: pickStr('windowsVersion'),
      macVersion: pickStr('macVersion'),
      linuxVersion: pickStr('linuxVersion'),
      iosVersion: pickStr('iosVersion'),
      androidVersion: pickStr('androidVersion'),
      windowsDownloadUrl: pickStr('windowsDownloadUrl'),
      macDownloadUrl: pickStr('macDownloadUrl'),
      linuxDownloadUrl: pickStr('linuxDownloadUrl'),
      iosDownloadUrl: pickStr('iosDownloadUrl'),
      androidDownloadUrl: pickStr('androidDownloadUrl'),
      releaseNotes: notes,
      releasePageUrl: pickStr('releasePageUrl'),
      forceUpdate: json['forceUpdate'] == true,
    );
  }
}
