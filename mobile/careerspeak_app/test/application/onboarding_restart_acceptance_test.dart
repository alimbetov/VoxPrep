import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/learning_vertical.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/universal_catalogue_graph.dart';
import 'package:careerspeak_app/application/content_delivery/vertical_catalogue_presentation.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/learner_selection_normalizer.dart';
import 'package:careerspeak_app/application/services/learner_selection_service.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_learner_selection_repository.dart';
import 'package:careerspeak_app/data/local/drift_onboarding_state_repository.dart';
import 'package:careerspeak_app/domain/learner_selection.dart';
import 'package:careerspeak_app/domain/onboarding_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('onboarding restart acceptance', () {
    test(
      'O1 resumes at English level after goal survives real DB reopen',
      () async {
        final harness = await _RestartHarness.create();
        addTearDown(harness.dispose);

        final first = harness.open();
        final service = LearnerSelectionService(
          repository: DriftLearnerSelectionRepository(first),
          normalizer: const LearnerSelectionNormalizer(),
        );
        final selected = await service.selectGoal(
          graph: _graph(),
          goalCode: 'JOB_INTERVIEW',
        );
        expect(selected, isA<Success<LearnerSelection>>());
        await first.close();

        final reopened = harness.open();
        final selection = _selection(
          await DriftLearnerSelectionRepository(reopened).getSelection(),
        );
        final onboarding = _onboarding(
          await DriftOnboardingStateRepository(reopened).getState(),
        );

        expect(selection.selectedGoalCode, 'JOB_INTERVIEW');
        expect(onboarding.nextStep(selection), OnboardingStep.englishLevel);
        await reopened.close();
      },
    );

    test(
      'O1 resumes at Support language after Not sure survives reopen',
      () async {
        final harness = await _RestartHarness.create();
        addTearDown(harness.dispose);

        final first = harness.open();
        final service = LearnerSelectionService(
          repository: DriftLearnerSelectionRepository(first),
          normalizer: const LearnerSelectionNormalizer(),
        );
        await service.selectGoal(graph: _graph(), goalCode: 'JOB_INTERVIEW');
        final level = await service.setLevelDecision(null);
        expect(level, isA<Success<LearnerSelection>>());
        await first.close();

        final reopened = harness.open();
        final selection = _selection(
          await DriftLearnerSelectionRepository(reopened).getSelection(),
        );
        final onboarding = _onboarding(
          await DriftOnboardingStateRepository(reopened).getState(),
        );

        expect(selection.levelDecisionMade, isTrue);
        expect(selection.selfAssessedLevelCode, isNull);
        expect(onboarding.nextStep(selection), OnboardingStep.supportLanguage);
        await reopened.close();
      },
    );

    test(
      'O2 skip survives restart without fabricating learning direction',
      () async {
        final harness = await _RestartHarness.create();
        addTearDown(harness.dispose);

        final first = harness.open();
        final onboardingRepository = DriftOnboardingStateRepository(first);
        final skipped = await onboardingRepository.compareAndSet(
          expectedGeneration: 0,
          completed: true,
        );
        expect(skipped, isA<Success<OnboardingState>>());
        await first.close();

        final reopened = harness.open();
        final onboarding = _onboarding(
          await DriftOnboardingStateRepository(reopened).getState(),
        );
        final selection = _selection(
          await DriftLearnerSelectionRepository(reopened).getSelection(),
        );

        expect(onboarding.completed, isTrue);
        expect(onboarding.nextStep(selection), OnboardingStep.complete);
        expect(selection.selectedGoalCode, isNull);
        expect(selection.selectedTrackCode, isNull);
        expect(selection.levelDecisionMade, isFalse);
        await reopened.close();
      },
    );

    test(
      'O3 new CURRENT graph invalidates inactive goal and track durably',
      () async {
        final harness = await _RestartHarness.create();
        addTearDown(harness.dispose);

        final first = harness.open();
        final repository = DriftLearnerSelectionRepository(first);
        final service = LearnerSelectionService(
          repository: repository,
          normalizer: const LearnerSelectionNormalizer(),
        );
        await service.selectGoal(graph: _graph(), goalCode: 'JOB_INTERVIEW');
        final track = await service.selectTrack(
          graph: _graph(),
          trackCode: 'JAVA_SENIOR',
        );
        expect(track, isA<Success<LearnerSelection>>());

        final normalized = await service.normalizeAgainst(
          _graph(goalActive: false),
        );
        final normalizedSelection = _selection(normalized);
        expect(normalizedSelection.selectedGoalCode, isNull);
        expect(normalizedSelection.selectedTrackCode, isNull);
        await first.close();

        final reopened = harness.open();
        final persisted = _selection(
          await DriftLearnerSelectionRepository(reopened).getSelection(),
        );
        expect(persisted.selectedGoalCode, isNull);
        expect(persisted.selectedTrackCode, isNull);
        await reopened.close();
      },
    );
  });
}

LearnerSelection _selection(Result<LearnerSelection> result) {
  return (result as Success<LearnerSelection>).value;
}

OnboardingState _onboarding(Result<OnboardingState> result) {
  return (result as Success<OnboardingState>).value;
}

final class _RestartHarness {
  _RestartHarness._(this.directory, this.file);

  final Directory directory;
  final File file;

  static Future<_RestartHarness> create() async {
    final directory = await Directory.systemTemp.createTemp(
      'careerspeak-onboarding-restart-',
    );
    return _RestartHarness._(
      directory,
      File('${directory.path}/careerspeak.sqlite'),
    );
  }

  CareerSpeakDatabase open() => CareerSpeakDatabase(NativeDatabase(file));

  Future<void> dispose() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

UniversalCatalogueGraph _graph({bool goalActive = true}) {
  return UniversalCatalogueGraph(
    sections: [
      VerticalSectionProjection(
        code: 'CAREER',
        title: 'Career',
        sortOrder: 0,
        active: true,
      ),
    ],
    verticals: [
      LearningVerticalProjection(
        code: 'JAVA',
        sectionCode: 'CAREER',
        title: 'Java',
        description: 'Java professional English',
        iconAssetId: 'java-icon',
        sortOrder: 0,
        active: true,
      ),
    ],
    goals: [
      LearningGoalProjection(
        code: 'JOB_INTERVIEW',
        verticalCode: 'JAVA',
        title: 'Job interview',
        description: 'Prepare for Java interviews',
        sortOrder: 0,
        active: goalActive,
      ),
    ],
    tracks: [
      LearningTrackProjection(
        code: 'JAVA_SENIOR',
        verticalCode: 'JAVA',
        goalCode: 'JOB_INTERVIEW',
        title: 'Java senior',
        description: 'Senior interview path',
        levelCode: 'B2',
        sortOrder: 0,
        active: true,
      ),
    ],
    collections: const [],
    presentation: VerticalCataloguePresentation(
      mode: VerticalCataloguePresentationMode.grid,
      showFeatured: false,
      showSeeAll: true,
    ),
  );
}
