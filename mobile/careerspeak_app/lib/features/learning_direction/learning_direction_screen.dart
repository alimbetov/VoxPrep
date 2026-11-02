import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'learning_direction_selection_panel.dart';

class LearningDirectionScreen extends StatelessWidget {
  const LearningDirectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Learning direction',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LearningDirectionSelectionPanel(
                    title: 'Choose your learning direction',
                    subtitle: 'Changing the goal keeps your English level and support-language preferences.',
                    onSelected: (_) {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/learn');
                      }
                    },
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
