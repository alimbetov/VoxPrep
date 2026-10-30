import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:drift/native.dart';

CareerSpeakDatabase createTestDatabase() {
  return CareerSpeakDatabase(NativeDatabase.memory());
}
