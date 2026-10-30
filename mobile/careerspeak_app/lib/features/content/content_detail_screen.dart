import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/repository_providers.dart';
import 'content_detail_panel.dart';

class ContentDetailScreen extends ConsumerWidget {
  const ContentDetailScreen({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(contentByCodeProvider(code));

    return item.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load content.\n$error'),
        ),
      ),
      data: (value) => value == null
          ? const Center(child: Text('Content not found.'))
          : ContentDetailPanel(item: value),
    );
  }
}
