import 'package:uuid/uuid.dart' as uuid_package;

/// A type-safe UUID wrapper that ensures all IDs are valid UUIDs.
class Uuid {
  final String _value;
  static final _uuidGenerator = uuid_package.Uuid();

  /// Creates a UUID from a string, validating it's a proper UUID format.
  /// Throws [FormatException] if the string is not a valid UUID.
  Uuid.fromString(String value) : _value = value {
    // Basic UUID validation (8-4-4-4-12 hex digits)
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    if (!uuidRegex.hasMatch(value)) {
      throw FormatException('Invalid UUID format: $value');
    }
  }

  /// Creates a new random UUID v4.
  Uuid.generate() : _value = _uuidGenerator.v4();

  /// Creates a UUID from a string, or generates a new one if null.
  factory Uuid.fromStringOrGenerate(String? value) {
    if (value == null) {
      return Uuid.generate();
    }
    return Uuid.fromString(value);
  }

  /// Returns the UUID as a string.
  @override
  String toString() => _value;

  /// Returns the UUID as a string (for explicit conversion).
  String toJson() => _value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Uuid &&
          runtimeType == other.runtimeType &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;
}

