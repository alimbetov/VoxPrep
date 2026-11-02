import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/catalogue_payload_providers.dart';
import '../../app/learner_selection_providers.dart';
import '../../application/content_delivery/universal_catalogue_graph.dart';
import '../../application/result/result.dart';

class LearningDirectionSelectionPanel extends ConsumerStatefulWidget {
  const LearningDirectionSelectionPanel({
    this.title = 'What do you want to practise?',
    this.subtitle = 'Choose a learning area, then choose your goal.',
    this.onSelected,
    super.key,
  });

  final String title;
  final String subtitle;
  final ValueChanged<String>? onSelected;

  @override
  ConsumerState<LearningDirectionSelectionPanel> createState() =>
      _LearningDirectionSelectionPanelState();
}

class _LearningDirectionSelectionPanelState
    extends ConsumerState<LearningDirectionSelectionPanel> {
  String? _selectedVerticalCode;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(currentUniversalCatalogueProvider);
    final selection = ref.watch(learnerSelectionProvider).asData?.value;

    return snapshotAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorState(
        message: 'Learning directions could not be loaded.',
        onRetry: () => ref.invalidate(currentUniversalCatalogueProvider),
      ),
      data: (snapshot) {
        if (snapshot == null) {
          return _ErrorState(
            message: 'No learning catalogue is available yet.',
            onRetry: () => ref.invalidate(currentUniversalCatalogueProvider),
          );
        }

        final graph = snapshot.graph;
        final activeGoals = graph.goals.where((goal) => goal.active).toList();
        final verticals = graph.verticals
            .where(
              (vertical) =>
                  vertical.active &&
                  activeGoals.any((goal) => goal.verticalCode == vertical.code),
            )
            .toList();
        if (verticals.isEmpty) {
          return const _ErrorState(
            message: 'No learning directions are currently available.',
          );
        }

        final selectedGoalCode = selection?.selectedGoalCode;
        final persistedVertical = _verticalForGoal(graph, selectedGoalCode);
        final requestedVertical = _selectedVerticalCode ?? persistedVertical;
        final selectedVerticalCode =
            verticals.any((vertical) => vertical.code == requestedVertical)
            ? requestedVertical!
            : verticals.first.code;
        final goals = activeGoals
            .where((goal) => goal.verticalCode == selectedVerticalCode)
            .toList();

        return ListView(
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(widget.subtitle, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final vertical in verticals)
                  ChoiceChip(
                    label: Text(vertical.title),
                    selected: vertical.code == selectedVerticalCode,
                    onSelected: _saving
                        ? null
                        : (_) => setState(
                            () => _selectedVerticalCode = vertical.code,
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            for (final goal in goals)
              Card(
                child: ListTile(
                  title: Text(goal.title),
                  subtitle: Text(goal.description),
                  leading: goal.code == selectedGoalCode
                      ? const Icon(Icons.check_circle_outline)
                      : null,
                  trailing: _saving ? null : const Icon(Icons.arrow_forward),
                  onTap: _saving ? null : () => _selectGoal(graph, goal.code),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _selectGoal(UniversalCatalogueGraph graph, String code) async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await ref
        .read(learnerSelectionServiceProvider)
        .selectGoal(graph: graph, goalCode: code);
    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case Success():
        widget.onSelected?.call(code);
      case FailureResult(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

String? _verticalForGoal(UniversalCatalogueGraph graph, String? goalCode) {
  if (goalCode == null) return null;
  for (final goal in graph.goals) {
    if (goal.code == goalCode && goal.active) return goal.verticalCode;
  }
  return null;
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
