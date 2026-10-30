import '../../domain/practice_test.dart';
import 'page.dart';

class PracticeTestQuery {
  const PracticeTestQuery({this.mode, this.page = const PageRequest()});

  final PracticeTestMode? mode;
  final PageRequest page;
}
