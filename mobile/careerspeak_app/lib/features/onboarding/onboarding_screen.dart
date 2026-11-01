import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/learner_selection_providers.dart';
import '../../app/onboarding_providers.dart';
import '../../application/result/result.dart';
import '../../domain/onboarding_state.dart';
import '../learning_direction/learning_direction_selection_panel.dart';
import '../settings/locale_selection_panel.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final stepAsync = ref.watch(onboardingStepProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: stepAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _ErrorState(
                  message: 'Onboarding state could not be loaded.',
                  onRetry: () {
                    ref.invalidate(onboardingStateProvider);
                    ref.invalidate(learnerSelectionProvider);
                  },
                ),
                data: (step) => _buildStep(context, step),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, OnboardingStep step) {
    if (step == OnboardingStep.complete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Set up your learning',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            TextButton(
              onPressed: _saving ? null : _skip,
              child: const Text('Skip'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Step ${step.index + 1} of 3',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: switch (step) {
            OnboardingStep.learningDirection =>
              const LearningDirectionSelectionPanel(),
            OnboardingStep.englishLevel => _EnglishLevelStep(
              saving: _saving,
              onSelected: _selectLevel,
            ),
            OnboardingStep.supportLanguage => Card(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: LocaleSelectionPanel(
                  primaryActionLabel: 'Finish setup',
                  onSaved: _finish,
                ),
              ),
            ),
            OnboardingStep.complete => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }

  Future<void> _selectLevel(String? code) async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await ref
        .read(learnerSelectionServiceProvider)
        .setLevelDecision(code);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result case FailureResult(:final failure)) {
      _showFailure(failure.message);
    }
  }

  Future<void> _finish() async {
    final result = await ref.read(onboardingControllerProvider).complete();
    if (!mounted) return;
    if (result case FailureResult(:final failure)) {
      _showFailure(failure.message);
      return;
    }
    context.go('/');
  }

  Future<void> _skip() async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await ref.read(onboardingControllerProvider).skip();
    if (!mounted) return;
    setState(() => _saving = false);
    if (result case FailureResult(:final failure)) {
      _showFailure(failure.message);
      return;
    }
    context.go('/');
  }

  void _showFailure(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EnglishLevelStep extends StatelessWidget {
  const _EnglishLevelStep({required this.saving, required this.onSelected});

  final bool saving;
  final Future<void> Function(String? code) onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          'What is your approximate English level?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'This only helps us focus the learning path. You can change it later.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        for (final entry in const <(String?, String)>[
          ('B1', 'B1 — Intermediate'),
          ('B2', 'B2 — Upper intermediate'),
          ('C1', 'C1 — Advanced'),
          (null, 'Not sure'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton.tonal(
              onPressed: saving ? null : () => onSelected(entry.$1),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(entry.$2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
