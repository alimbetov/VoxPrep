import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/repository_providers.dart';
import 'content_detail_panel.dart';

class ContentDetailScreen extends ConsumerWidget {
  const ContentDetailScreen({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(contentRepositoryProvider);
    final item = repository.byCode(code);

    if (item == null) {
      return const Center(child: Text('Content not found.'));
    }

    return ContentDetailPanel(item: item);
  }
}
