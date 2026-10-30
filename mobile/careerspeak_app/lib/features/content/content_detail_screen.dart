import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_content_repository.dart';
import 'content_detail_panel.dart';

class ContentDetailScreen extends ConsumerWidget {
  const ContentDetailScreen({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(mockContentRepositoryProvider);
    final item = repository.byCode(code);

    if (item == null) {
      return const Center(child: Text('Mock content not found.'));
    }

    return ContentDetailPanel(item: item);
  }
}
