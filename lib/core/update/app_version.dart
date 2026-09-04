/// Minimal semver for update comparison. Release tags are `vMAJOR.MINOR.PATCH`
/// (e.g. `v1.2.0`); pubspec versions add a build suffix that we ignore
/// (`1.2.0+4` → 1.2.0). No external dependency — this is all the updater needs.
library;

class AppVersion {
  final int major;
  final int minor;
  final int patch;

  const AppVersion(this.major, this.minor, this.patch);

  /// Parses `v1.2.0`, `1.2.0`, `1.2.0+4`, `1.2.0-rc1…` (build/pre-release
  /// suffixes ignored — they never affect the compare below).
  static AppVersion? tryParse(String? raw) {
    if (raw == null) return null;
    var text = raw.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('v')) text = text.substring(1);
    // Cut build metadata / pre-release suffixes — never the version dots.
    final plus = text.indexOf('+');
    if (plus > 0) text = text.substring(0, plus);
    final dash = text.indexOf('-');
    if (dash > 0) text = text.substring(0, dash);
    if (text.isEmpty) return null;

    final parts = text.split('.');
    if (parts.length < 3) return null;
    final major = int.tryParse(parts[0].trim());
    final minor = int.tryParse(parts[1].trim());
    final patch = int.tryParse(parts[2].trim());
    if (major == null || minor == null || patch == null) return null;
    return AppVersion(major, minor, patch);
  }

  /// True when [other] is a newer release than this version.
  bool isNewerThan(AppVersion other) {
    if (major != other.major) return major > other.major;
    if (minor != other.minor) return minor > other.minor;
    return patch > other.patch;
  }

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}