import 'dart:io';

import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'typed content projection survives file-backed close and reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'careerspeak-c2-typed-',
      );
      final file = File('${directory.path}/careerspeak.sqlite');
      final now = DateTime.utc(2026, 10, 31, 9);

      final first = CareerSpeakDatabase(NativeDatabase(file));
      await first
          .into(first.typedContentReads)
          .insert(
            TypedContentReadsCompanion.insert(
              contentCode: 'JAVA_Q_001',
              contentType: 'INTERVIEW',
              revision: 3,
              checksum: 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
              categoryCode: 'JAVA_BACKEND',
              levelCode: 'SENIOR',
              skillCodesJson: '["COMMUNICATION","SYSTEM_DESIGN"]',
              bodyKind: 'interview',
              bodyJson: '{"kind":"interview","prompt":"What is dependency injection?","modelAnswer":"Dependencies are supplied externally.","keyPoints":["loose coupling","testability"]}',
              createdAt: now,
            ),
          );
      await first.close();

      final reopened = CareerSpeakDatabase(NativeDatabase(file));
      final row = await reopened.select(reopened.typedContentReads).getSingle();
      expect(row.contentCode, 'JAVA_Q_001');
      expect(row.revision, 3);
      expect(row.categoryCode, 'JAVA_BACKEND');
      expect(row.levelCode, 'SENIOR');
      expect(row.skillCodesJson, '["COMMUNICATION","SYSTEM_DESIGN"]');
      expect(row.bodyKind, 'interview');
      expect(
        row.bodyJson,
        contains('"keyPoints":["loose coupling","testability"]'),
      );
      await reopened.close();

      await directory.delete(recursive: true);
    },
  );
}
