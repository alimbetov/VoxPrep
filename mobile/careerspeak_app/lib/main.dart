import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/application_bootstrap_providers.dart';
import 'app/careerspeak_app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ProductionBootstrapHost(child: CareerSpeakApp()),
    ),
  );
}
