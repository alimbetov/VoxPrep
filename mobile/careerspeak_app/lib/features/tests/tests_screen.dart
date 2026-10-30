import 'package:flutter/material.dart';

class TestsScreen extends StatelessWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Tests', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Mock assessment catalogue for UI qualification.'),
        const SizedBox(height: 20),
        _TestCard(
          title: 'Java Senior · Quick Test',
          subtitle: '10 questions · Java Core, Concurrency, Spring',
          icon: Icons.code,
        ),
        _TestCard(
          title: 'IELTS Speaking · Environment',
          subtitle: 'Part 2 + Part 3 · 12 questions',
          icon: Icons.language,
        ),
      ],
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mock test session opens in P1.2.')),
              ),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}
