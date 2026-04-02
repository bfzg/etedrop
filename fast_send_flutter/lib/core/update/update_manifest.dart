class UpdateManifest {
  final String latestVersion;
  final String? windowsDownloadUrl;
  final String? macDownloadUrl;
  /// Release notes by language code (e.g. "zh", "en").
  /// Each item is a single line, displayed as a list.
  final Map<String, List<String>> releaseNotes;
  final String? releasePageUrl;
  final bool forceUpdate;

  const UpdateManifest({
    required this.latestVersion,
    this.windowsDownloadUrl,
    this.macDownloadUrl,
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

    return UpdateManifest(
      latestVersion: (json['latestVersion'] as String?)?.trim() ?? '',
      windowsDownloadUrl: (json['windowsDownloadUrl'] as String?)?.trim(),
      macDownloadUrl: (json['macDownloadUrl'] as String?)?.trim(),
      releaseNotes: notes,
      releasePageUrl: (json['releasePageUrl'] as String?)?.trim(),
      forceUpdate: json['forceUpdate'] == true,
    );
  }
}

