import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/careerspeak_app.dart';
import 'app/release_legal_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  validateReleaseLegalConfiguration();

  runApp(const ProviderScope(child: CareerSpeakApp()));
}
