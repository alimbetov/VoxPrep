import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../settings/locale_selection_panel.dart';

class LocaleOnboardingScreen extends StatelessWidget {
  const LocaleOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Text(
                  'Set up your language',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your country first. CareerSpeak will ask Backend which learning-support languages are enabled for that country.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: LocaleSelectionPanel(
                      primaryActionLabel: 'Continue',
                      onSaved: () => context.go('/'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
