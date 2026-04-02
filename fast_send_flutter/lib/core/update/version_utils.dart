class VersionUtils {
  VersionUtils._();

  /// Parses versions like:
  /// - "1.2.3"
  /// - "1.2.3+45" (build ignored)
  /// - "v1.2.3" (leading v ignored)
  static List<int> parseTriplet(String v) {
    var s = v.trim();
    if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
    final plus = s.indexOf('+');
    if (plus >= 0) s = s.substring(0, plus);
    final parts = s.split('.');
    int p(int i) => (i < parts.length) ? int.tryParse(parts[i]) ?? 0 : 0;
    return [p(0), p(1), p(2)];
  }

  /// Returns true if [a] < [b].
  static bool isLess(String a, String b) {
    final va = parseTriplet(a);
    final vb = parseTriplet(b);
    for (var i = 0; i < 3; i++) {
      if (va[i] != vb[i]) return va[i] < vb[i];
    }
    return false;
  }
}

