import 'package:drift/drift.dart';

class AssessmentQuestionReads extends Table {
  TextColumn get questionCode => text()();
  IntColumn get revision => integer()();
  TextColumn get checksum => text()();
  TextColumn get bodyKind => text()();
  TextColumn get prompt => text()();
  TextColumn get optionsJson => text()();
  IntColumn get correctOptionIndex => integer()();
  TextColumn get skillCode => text()();
  TextColumn get explanation => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {questionCode, revision};

  @override
  List<String> get customConstraints => const [
    'CHECK (revision > 0)',
    'CHECK (length(trim(question_code)) > 0)',
    'CHECK (length(trim(checksum)) = 64)',
    "CHECK (body_kind = 'singleChoice')",
    'CHECK (length(trim(prompt)) > 0)',
    'CHECK (length(trim(options_json)) > 0)',
    'CHECK (correct_option_index >= 0)',
    'CHECK (length(trim(skill_code)) > 0)',
    'CHECK (length(trim(explanation)) > 0)',
  ];
}

class PracticeTestRevisionReads extends Table {
  TextColumn get practiceTestCode => text()();
  IntColumn get revision => integer()();
  TextColumn get checksum => text()();
  TextColumn get title => text()();
  TextColumn get subtitle => text()();
  TextColumn get mode => text()();
  IntColumn get passingScoreBasisPoints => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {practiceTestCode, revision};

  @override
  List<String> get customConstraints => const [
    'CHECK (revision > 0)',
    'CHECK (length(trim(practice_test_code)) > 0)',
    'CHECK (length(trim(checksum)) = 64)',
    'CHECK (length(trim(title)) > 0)',
    'CHECK (length(trim(subtitle)) > 0)',
    "CHECK (mode IN ('learn', 'exam', 'quick'))",
    'CHECK (passing_score_basis_points BETWEEN 0 AND 10000)',
  ];
}

class PracticeTestQuestionRefs extends Table {
  TextColumn get practiceTestCode => text()();
  IntColumn get practiceTestRevision => integer()();
  IntColumn get questionOrder => integer()();
  TextColumn get questionCode => text()();
  IntColumn get questionRevision => integer()();
  TextColumn get questionChecksum => text()();
  IntColumn get points => integer()();

  @override
  Set<Column<Object>> get primaryKey => {
    practiceTestCode,
    practiceTestRevision,
    questionOrder,
  };

  @override
  List<String> get customConstraints => const [
    'CHECK (practice_test_revision > 0)',
    'CHECK (question_order >= 0)',
    'CHECK (question_revision > 0)',
    'CHECK (length(trim(question_checksum)) = 64)',
    'CHECK (points > 0)',
    'UNIQUE (practice_test_code, practice_test_revision, question_code, question_revision)',
  ];
}
