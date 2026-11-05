import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/repository_providers.dart';
import '../../application/result/result.dart';
import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import '../../domain/last_opened_content.dart';
import '../shared/content_cover.dart';
import 'content_detail_panel.dart';

class ContentDetailScreen extends ConsumerStatefulWidget {
  const ContentDetailScreen({required this.identity, super.key});

  final ContentIdentity identity;

  @override
  ConsumerState<ContentDetailScreen> createState() =>
      _ContentDetailScreenState();
}

class _ContentDetailScreenState extends ConsumerState<ContentDetailScreen> {
  int? _recordedRevision;

  @override
  void didUpdateWidget(covariant ContentDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.identity != widget.identity) {
      _recordedRevision = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(contentByIdentityProvider(widget.identity));

    return item.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load content.\n$error'),
        ),
      ),
      data: (value) {
        if (value == null) {
          return const Center(child: Text('Content not found.'));
        }

        _recordOpened(value);
        final localized = ref.watch(
          localizedContentProvider(
            LocalizedContentRequest(
              identity: widget.identity,
              contentRevision: value.revision,
            ),
          ),
        );
        final localizedHint = localized.asData?.value?.hint;
        final typed = ref.watch(
          typedContentByIdentityProvider(widget.identity),
        );

        return Column(
          children: [
            ContentCover(
              content: widget.identity,
              revision: value.revision,
              height: 220,
            ),
            Expanded(
              child: ContentDetailPanel(
                item: value,
                localizedHint: localizedHint,
                typedBody: typed.asData?.value,
                typedBodyLoading: typed.isLoading,
                typedBodyError: typed.hasError,
              ),
            ),
          ],
        );
      },
    );
  }

  void _recordOpened(ContentItem item) {
    if (_recordedRevision == item.revision) return;
    _recordedRevision = item.revision;
    unawaited(
      ref
          .read(lastOpenedContentRepositoryProvider)
          .recordOpened(
            identity: ContentIdentity.fromItem(item),
            contentRevision: item.revision,
          )
          .then((result) {
            if (result case FailureResult<LastOpenedContent>()) {
              if (mounted && _recordedRevision == item.revision) {
                _recordedRevision = null;
              }
            }
          }),
    );
  }
}
