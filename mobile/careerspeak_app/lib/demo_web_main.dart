import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/theme/careerspeak_theme.dart';
import 'application/query/practice_test_query.dart';
import 'data/mock/generated_demo_content.dart';
import 'data/mock/mock_test_repository.dart';
import 'domain/content_item.dart';
import 'domain/practice_test.dart';

const _demoEnabled = bool.fromEnvironment('VOXPREP_DEMO');

/// Intentionally separate from real application bootstrap. This entrypoint
/// cannot create Drift, HttpApiClient or an in-app purchase.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kDebugMode || !_demoEnabled) {
    throw StateError('DEV Web requires --dart-define=VOXPREP_DEMO=true');
  }
  runApp(const VoxPrepWebDemoApp());
}

class VoxPrepWebDemoApp extends StatefulWidget {
  const VoxPrepWebDemoApp({super.key});

  @override
  State<VoxPrepWebDemoApp> createState() => _WebDemoState();
}

class _WebDemoState extends State<VoxPrepWebDemoApp> {
  int tab = 0;
  bool dark = false;
  bool fakeFull = false;
  String filter = '';
  final Set<String> favorites = {};
  final Set<String> completed = {};
  final Future<List<PracticeTestSummary>> tests = const MockTestRepository()
      .watchTests(const PracticeTestQuery())
      .first
      .then((result) => result.getOrThrow().items);

  static const labels = ['Home', 'Learn', 'Tests', 'Review', 'Settings'];
  static const icons = [
    Icons.home_outlined,
    Icons.menu_book_outlined,
    Icons.quiz_outlined,
    Icons.bookmark_outline,
    Icons.settings_outlined,
  ];

  bool isFree(ContentItem item) {
    final first = generatedDemoContentItems.firstWhere(
      (candidate) => candidate.category == item.category,
    );
    return first.code == item.code;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoxPrep Web Demo',
      debugShowCheckedModeBanner: false,
      theme: CareerSpeakTheme.light(),
      darkTheme: CareerSpeakTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Builder(
        builder: (context) {
          final wide = MediaQuery.sizeOf(context).width >= 720;
          return Scaffold(
            appBar: AppBar(
              title: const Text('VoxPrep — DEV Web Preview'),
              actions: [
                Center(child: Text(fakeFull ? 'DEMO FULL' : 'DEMO FREE')),
                const SizedBox(width: 16),
              ],
            ),
            body: Row(
              children: [
                if (wide)
                  NavigationRail(
                    selectedIndex: tab,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: (index) {
                      setState(() => tab = index);
                    },
                    destinations: [
                      for (var i = 0; i < labels.length; i++)
                        NavigationRailDestination(
                          icon: Icon(icons[i]),
                          label: Text(labels[i]),
                        ),
                    ],
                  ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1024),
                      child: switch (tab) {
                        0 => home(context),
                        1 => learn(context),
                        2 => practice(context),
                        3 => review(context),
                        _ => settings(context),
                      },
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: wide
                ? null
                : NavigationBar(
                    selectedIndex: tab,
                    onDestinationSelected: (index) {
                      setState(() => tab = index);
                    },
                    destinations: [
                      for (var i = 0; i < labels.length; i++)
                        NavigationDestination(
                          icon: Icon(icons[i]),
                          label: labels[i],
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget home(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Welcome to VoxPrep',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'This is a separate DEV mock preview, not the production '
          'Flutter learner bootstrap. No Backend, SQLite, or Store API.',
        ),
        const SizedBox(height: 16),
        Text(
          '${generatedDemoContentItems.length} demo lessons',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...generatedDemoContentItems.take(4).map(contentTile),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => setState(() => tab = 1),
          child: const Text('Explore learning'),
        ),
      ],
    );
  }

  Widget learn(BuildContext context) {
    final value = filter.trim().toLowerCase();
    final found = generatedDemoContentItems.where((item) {
      return value.isEmpty ||
          item.title.toLowerCase().contains(value) ||
          item.category.toLowerCase().contains(value);
    });
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Learning catalogue',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search lessons',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => filter = value),
        ),
        const SizedBox(height: 16),
        ...found.map(contentTile),
        if (found.isEmpty) const Text('No matching demo learning materials.'),
      ],
    );
  }

  Widget contentTile(ContentItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.title),
        subtitle: Text(
          '${item.category} · ${item.level} · ${item.minutes} min',
        ),
        trailing: Text(isFree(item) ? 'FREE' : 'FULL'),
        onTap: () => openLesson(item),
      ),
    );
  }

  void openLesson(ContentItem item) {
    if (!isFree(item) && !fakeFull) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('FULL locked — demo only'),
          content: const Text(
            'You can simulate FULL locally. No purchase, credential or '
            'backend entitlement is created.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() => fakeFull = true);
                Navigator.pop(context);
              },
              child: const Text('Simulate FULL'),
            ),
          ],
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Text(item.description),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (!favorites.add(item.code)) {
                  favorites.remove(item.code);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Toggle favorite'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => completed.add(item.code));
              Navigator.pop(context);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Widget practice(BuildContext context) {
    return FutureBuilder<List<PracticeTestSummary>>(
      future: tests,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Demo tests unavailable.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Practice tests',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            for (final item in snapshot.data!)
              Card(
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text(item.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await const MockTestRepository().getByCode(
                      item.code,
                    );
                    if (!context.mounted) return;
                    final exam = result.getOrThrow();
                    if (exam == null) return;
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute(builder: (_) => _DemoExam(exam: exam)),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget review(BuildContext context) {
    final items = generatedDemoContentItems.where(
      (item) => completed.contains(item.code) || favorites.contains(item.code),
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Local demo progress',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text('${favorites.length} favorites · ${completed.length} completed'),
        const SizedBox(height: 16),
        ...items.map(contentTile),
        if (items.isEmpty)
          const Text('Favorite or complete lessons to see them here.'),
      ],
    );
  }

  Widget settings(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Demo settings',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SwitchListTile(
          title: const Text('Dark theme'),
          value: dark,
          onChanged: (value) => setState(() => dark = value),
        ),
        SwitchListTile(
          title: const Text('Simulate FULL — not a real purchase'),
          value: fakeFull,
          onChanged: (value) => setState(() => fakeFull = value),
        ),
        OutlinedButton(
          onPressed: () => setState(() {
            favorites.clear();
            completed.clear();
            fakeFull = false;
          }),
          child: const Text('Reset demo progress'),
        ),
      ],
    );
  }
}

class _DemoExam extends StatefulWidget {
  const _DemoExam({required this.exam});

  final PracticeTest exam;

  @override
  State<_DemoExam> createState() => _DemoExamState();
}

class _DemoExamState extends State<_DemoExam> {
  int index = 0;
  bool finished = false;
  final Map<int, int> answers = {};

  @override
  Widget build(BuildContext context) {
    final questions = widget.exam.questions;
    return Scaffold(
      appBar: AppBar(title: Text(widget.exam.title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (finished) ...[
            Text(
              'Result: ${calculatePracticeTestScore(widget.exam, answers)} / ${questions.length}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            for (final question in questions)
              Card(
                child: ListTile(
                  title: Text(question.prompt),
                  subtitle: Text(question.explanation),
                ),
              ),
          ] else ...[
            Text(
              'Question ${index + 1} / ${questions.length}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(questions[index].prompt),
            const SizedBox(height: 12),
            for (var i = 0; i < questions[index].options.length; i++)
              ListTile(
                title: Text(questions[index].options[i]),
                leading: Icon(
                  answers[index] == i
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                onTap: () => setState(() => answers[index] = i),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: answers[index] == null
                  ? null
                  : () => setState(() {
                      if (index == questions.length - 1) {
                        finished = true;
                      } else {
                        index++;
                      }
                    }),
              child: Text(index == questions.length - 1 ? 'Submit' : 'Next'),
            ),
          ],
        ],
      ),
    );
  }
}
