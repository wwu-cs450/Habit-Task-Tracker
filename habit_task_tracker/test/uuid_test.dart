import 'package:flutter_test/flutter_test.dart';
import 'package:habit_task_tracker/uuid.dart';

void main() {
  group('Uuid.fromString', () {
    test('creates UUID from valid lowercase string', () {
      const validUuid = '550e8400-e29b-41d4-a716-446655440000';
      final uuid = Uuid.fromString(validUuid);
      expect(uuid.toString(), equals(validUuid));
    });

    test('creates UUID from valid uppercase string', () {
      const validUuid = '550E8400-E29B-41D4-A716-446655440000';
      final uuid = Uuid.fromString(validUuid);
      expect(uuid.toString(), equals(validUuid));
    });

    test('creates UUID from valid mixed case string', () {
      const validUuid = '550e8400-E29b-41d4-A716-446655440000';
      final uuid = Uuid.fromString(validUuid);
      expect(uuid.toString(), equals(validUuid));
    });

    test(
      'throws FormatException for invalid UUID format - missing hyphens',
      () {
        const invalidUuid = '550e8400e29b41d4a716446655440000';
        expect(
          () => Uuid.fromString(invalidUuid),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('throws FormatException for invalid UUID format - wrong length', () {
      const invalidUuid = '550e8400-e29b-41d4-a716-44665544000';
      expect(
        () => Uuid.fromString(invalidUuid),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'throws FormatException for invalid UUID format - invalid characters',
      () {
        const invalidUuid = '550e8400-e29b-41d4-a716-44665544000g';
        expect(
          () => Uuid.fromString(invalidUuid),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('throws FormatException for empty string', () {
      expect(() => Uuid.fromString(''), throwsA(isA<FormatException>()));
    });

    test('throws FormatException for non-UUID string', () {
      expect(
        () => Uuid.fromString('not-a-uuid'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Uuid.generate', () {
    test('generates valid UUID v4', () {
      final uuid = Uuid.generate();
      final uuidString = uuid.toString();

      // Check format: 8-4-4-4-12 hex digits
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(uuidString), isTrue);
    });

    test('generates different UUIDs on each call', () {
      final uuid1 = Uuid.generate();
      final uuid2 = Uuid.generate();
      expect(uuid1, isNot(equals(uuid2)));
    });

    test('generated UUID can be parsed back', () {
      final uuid = Uuid.generate();
      final uuidString = uuid.toString();
      final parsedUuid = Uuid.fromString(uuidString);
      expect(parsedUuid, equals(uuid));
    });
  });

  group('Uuid.fromStringOrGenerate', () {
    test('generates new UUID when value is null', () {
      final uuid = Uuid.fromStringOrGenerate(null);
      expect(uuid, isA<Uuid>());
      final uuidString = uuid.toString();
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(uuidString), isTrue);
    });

    test('creates UUID from valid string', () {
      const validUuid = '550e8400-e29b-41d4-a716-446655440000';
      final uuid = Uuid.fromStringOrGenerate(validUuid);
      expect(uuid.toString(), equals(validUuid));
    });

    test('throws FormatException for invalid string', () {
      const invalidUuid = 'not-a-uuid';
      expect(
        () => Uuid.fromStringOrGenerate(invalidUuid),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Uuid.toString', () {
    test('returns the UUID string value', () {
      const uuidString = '550e8400-e29b-41d4-a716-446655440000';
      final uuid = Uuid.fromString(uuidString);
      expect(uuid.toString(), equals(uuidString));
    });
  });

  group('Uuid.toJson', () {
    test('returns the UUID string value', () {
      const uuidString = '550e8400-e29b-41d4-a716-446655440000';
      final uuid = Uuid.fromString(uuidString);
      expect(uuid.toJson(), equals(uuidString));
    });

    test('toJson returns same value as toString', () {
      final uuid = Uuid.generate();
      expect(uuid.toJson(), equals(uuid.toString()));
    });
  });

  group('Uuid equality', () {
    test('two UUIDs with same value are equal', () {
      const uuidString = '550e8400-e29b-41d4-a716-446655440000';
      final uuid1 = Uuid.fromString(uuidString);
      final uuid2 = Uuid.fromString(uuidString);
      expect(uuid1, equals(uuid2));
      expect(uuid1 == uuid2, isTrue);
    });

    test('two UUIDs with different values are not equal', () {
      final uuid1 = Uuid.fromString('550e8400-e29b-41d4-a716-446655440000');
      final uuid2 = Uuid.fromString('550e8400-e29b-41d4-a716-446655440001');
      expect(uuid1, isNot(equals(uuid2)));
      expect(uuid1 == uuid2, isFalse);
    });

    test('UUID is not equal to non-Uuid object', () {
      final uuid = Uuid.generate();
      expect(uuid == 'string', isFalse);
      expect(uuid == 123, isFalse);
    });

    test('identical UUIDs are equal', () {
      final uuid = Uuid.generate();
      expect(uuid == uuid, isTrue);
    });
  });

  group('Uuid hashCode', () {
    test('two equal UUIDs have same hashCode', () {
      const uuidString = '550e8400-e29b-41d4-a716-446655440000';
      final uuid1 = Uuid.fromString(uuidString);
      final uuid2 = Uuid.fromString(uuidString);
      expect(uuid1.hashCode, equals(uuid2.hashCode));
    });

    test('UUID can be used as Map key', () {
      final uuid1 = Uuid.fromString('550e8400-e29b-41d4-a716-446655440000');
      final uuid2 = Uuid.fromString('550e8400-e29b-41d4-a716-446655440000');
      final map = <Uuid, String>{};
      map[uuid1] = 'value1';
      expect(map[uuid2], equals('value1'));
    });
  });
}
