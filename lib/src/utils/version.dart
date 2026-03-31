/// A parsed version with separate number and metadata components.
class Version {
  /// The version number (e.g., "1.0.0").
  final String number;

  /// The build metadata after the '+' delimiter, or null if none.
  final String? metadata;

  /// The original combined version string (e.g., "1.0.0+42").
  final String combined;

  Version._({required this.number, required this.metadata, required this.combined});

  /// Parses a version string in the format "major.minor.patch" or
  /// "major.minor.patch+metadata".
  ///
  /// Throws a [FormatException] if the input does not match the
  /// expected format. Metadata may contain additional '+' characters.
  static Version parse(String input) {
    if (!RegExp(r'^\d+\.\d+\.\d+(?:\+.+)?$').hasMatch(input)) {
      throw FormatException(
        'Invalid version format. Expected: major.minor.patch '
        'or major.minor.patch+metadata.',
        input,
      );
    }
    final parts = input.split('+');
    final number = parts[0];
    final metadata = parts.length > 1 ? parts.sublist(1).join('+') : null;
    return Version._(number: number, metadata: metadata, combined: input);
  }

  @override
  String toString() => combined;
}
