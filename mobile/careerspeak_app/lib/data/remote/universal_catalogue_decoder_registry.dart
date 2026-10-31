import '../../application/content_delivery/catalogue_payload.dart';
import '../../application/content_delivery/catalogue_revision_ref.dart';
import '../../application/content_delivery/product_catalog.dart';
import '../../domain/content_item.dart';
import 'learning_vertical_decoder.dart';
import 'vertical_catalogue_presentation_decoder.dart';

final class UniversalCatalogueDecoderRegistry {
  const UniversalCatalogueDecoderRegistry({
    this.verticalDecoder = const LearningVerticalDecoder(),
    this.presentationDecoder = const VerticalCataloguePresentationDecoder(),
  });

  final LearningVerticalDecoder verticalDecoder;
  final VerticalCataloguePresentationDecoder presentationDecoder;

  Object decode(CataloguePayload payload) {
    return switch (payload.ref.kind) {
      CatalogueKind.verticalSections => presentationDecoder.decodeSections(
        payload.items,
      ),
      CatalogueKind.verticals => verticalDecoder.decodeAll(payload.items),
      CatalogueKind.verticalPresentation => _decodePresentation(payload),
      CatalogueKind.learningGoals => _decodeAll(
        payload.items,
        _decodeGoal,
        'learning goals',
      ),
      CatalogueKind.learningTracks => _decodeAll(
        payload.items,
        _decodeTrack,
        'learning tracks',
      ),
      CatalogueKind.learningCollections => _decodeAll(
        payload.items,
        _decodeCollection,
        'learning collections',
      ),
      _ => payload.items,
    };
  }

  Object _decodePresentation(CataloguePayload payload) {
    if (payload.items.length != 1) {
      throw const FormatException(
        'Vertical presentation catalogue must contain exactly one item.',
      );
    }
    return presentationDecoder.decodePresentation(payload.items.single);
  }

  List<T> _decodeAll<T>(
    List<Object> items,
    T Function(Object value) decoder,
    String label,
  ) {
    final decoded = items.map(decoder).toList(growable: false);
    final seen = <String>{};
    for (final item in decoded) {
      final code = switch (item) {
        LearningGoalProjection value => value.code,
        LearningTrackProjection value => value.code,
        LearningCollectionProjection value => value.code,
        _ => throw StateError('Unsupported decoded catalogue item.'),
      };
      if (!seen.add(code)) {
        throw FormatException('$label contain duplicate code $code.');
      }
    }
    return List<T>.unmodifiable(decoded);
  }

  LearningGoalProjection _decodeGoal(Object value) {
    final map = _object(value, 'Learning goal');
    _rejectUnexpected(map, const <String>{
      'code',
      'verticalCode',
      'title',
      'description',
      'sortOrder',
      'active',
    }, 'Learning goal');
    return LearningGoalProjection(
      code: _string(map, 'code', 'Learning goal'),
      verticalCode: _string(map, 'verticalCode', 'Learning goal'),
      title: _string(map, 'title', 'Learning goal'),
      description: _string(map, 'description', 'Learning goal'),
      sortOrder: _int(map, 'sortOrder', 'Learning goal'),
      active: _bool(map, 'active', 'Learning goal'),
    );
  }

  LearningTrackProjection _decodeTrack(Object value) {
    final map = _object(value, 'Learning track');
    _rejectUnexpected(map, const <String>{
      'code',
      'verticalCode',
      'goalCode',
      'title',
      'description',
      'levelCode',
      'careerTrackCode',
      'sortOrder',
      'active',
    }, 'Learning track');
    return LearningTrackProjection(
      code: _string(map, 'code', 'Learning track'),
      verticalCode: _string(map, 'verticalCode', 'Learning track'),
      goalCode: _string(map, 'goalCode', 'Learning track'),
      title: _string(map, 'title', 'Learning track'),
      description: _string(map, 'description', 'Learning track'),
      levelCode: _string(map, 'levelCode', 'Learning track'),
      careerTrackCode: _optionalString(
        map,
        'careerTrackCode',
        'Learning track',
      ),
      sortOrder: _int(map, 'sortOrder', 'Learning track'),
      active: _bool(map, 'active', 'Learning track'),
    );
  }

  LearningCollectionProjection _decodeCollection(Object value) {
    final map = _object(value, 'Learning collection');
    _rejectUnexpected(map, const <String>{
      'code',
      'verticalCode',
      'trackCode',
      'title',
      'description',
      'sortOrder',
      'active',
      'members',
    }, 'Learning collection');
    final members = _list(
      map,
      'members',
      'Learning collection',
    ).map(_decodeCollectionMember).toList(growable: false);
    return LearningCollectionProjection(
      code: _string(map, 'code', 'Learning collection'),
      verticalCode: _string(map, 'verticalCode', 'Learning collection'),
      trackCode: _string(map, 'trackCode', 'Learning collection'),
      title: _string(map, 'title', 'Learning collection'),
      description: _string(map, 'description', 'Learning collection'),
      sortOrder: _int(map, 'sortOrder', 'Learning collection'),
      active: _bool(map, 'active', 'Learning collection'),
      members: members,
    );
  }

  LearningCollectionMember _decodeCollectionMember(Object value) {
    final map = _object(value, 'Collection member');
    _rejectUnexpected(map, const <String>{
      'position',
      'type',
      'content',
      'practiceTest',
    }, 'Collection member');
    final position = _int(map, 'position', 'Collection member');
    final type = LearningCollectionMemberType.fromWireName(
      _string(map, 'type', 'Collection member'),
    );
    final content = map['content'];
    final practiceTest = map['practiceTest'];

    return switch (type) {
      LearningCollectionMemberType.content => _contentMember(
        position: position,
        content: content,
        practiceTest: practiceTest,
      ),
      LearningCollectionMemberType.practiceTest => _practiceTestMember(
        position: position,
        content: content,
        practiceTest: practiceTest,
      ),
    };
  }

  LearningCollectionMember _contentMember({
    required int position,
    required Object? content,
    required Object? practiceTest,
  }) {
    if (content == null || practiceTest != null) {
      throw const FormatException(
        'CONTENT member must contain content and no practiceTest.',
      );
    }
    return LearningCollectionMember.content(
      position: position,
      content: _decodeContentRef(content),
    );
  }

  LearningCollectionMember _practiceTestMember({
    required int position,
    required Object? content,
    required Object? practiceTest,
  }) {
    if (practiceTest == null || content != null) {
      throw const FormatException(
        'PRACTICE_TEST member must contain practiceTest and no content.',
      );
    }
    return LearningCollectionMember.practiceTest(
      position: position,
      practiceTest: _decodePracticeTestRef(practiceTest),
    );
  }

  ContentRevisionRef _decodeContentRef(Object value) {
    final map = _object(value, 'Content revision ref');
    _rejectUnexpected(map, const <String>{
      'contentCode',
      'contentType',
      'revision',
      'checksum',
    }, 'Content revision ref');
    final typeName = _string(map, 'contentType', 'Content revision ref');
    final type = ContentType.values
        .where((item) => item.name == typeName)
        .firstOrNull;
    if (type == null) {
      throw FormatException('Unsupported contentType $typeName.');
    }
    return ContentRevisionRef(
      contentCode: _string(map, 'contentCode', 'Content revision ref'),
      contentType: type,
      revision: _int(map, 'revision', 'Content revision ref'),
      checksum: _string(map, 'checksum', 'Content revision ref'),
    );
  }

  PracticeTestRevisionRef _decodePracticeTestRef(Object value) {
    final map = _object(value, 'Practice test revision ref');
    _rejectUnexpected(map, const <String>{
      'practiceTestCode',
      'revision',
      'checksum',
    }, 'Practice test revision ref');
    return PracticeTestRevisionRef(
      practiceTestCode: _string(
        map,
        'practiceTestCode',
        'Practice test revision ref',
      ),
      revision: _int(map, 'revision', 'Practice test revision ref'),
      checksum: _string(map, 'checksum', 'Practice test revision ref'),
    );
  }
}

Map<String, dynamic> _object(Object value, String entity) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$entity must be an object.');
  }
  return value;
}

void _rejectUnexpected(
  Map<String, dynamic> value,
  Set<String> allowed,
  String entity,
) {
  final unexpected = value.keys.where((key) => !allowed.contains(key));
  if (unexpected.isNotEmpty) {
    throw FormatException(
      '$entity contains non-publication fields: ${unexpected.join(', ')}',
    );
  }
}

String _string(Map<String, dynamic> map, String field, String entity) {
  final value = map[field];
  if (value is! String) {
    throw FormatException('$entity.$field must be a string.');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> map, String field, String entity) {
  final value = map[field];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('$entity.$field must be a string or null.');
  }
  return value;
}

int _int(Map<String, dynamic> map, String field, String entity) {
  final value = map[field];
  if (value is! int) {
    throw FormatException('$entity.$field must be an int.');
  }
  return value;
}

bool _bool(Map<String, dynamic> map, String field, String entity) {
  final value = map[field];
  if (value is! bool) {
    throw FormatException('$entity.$field must be a bool.');
  }
  return value;
}

List<Object> _list(Map<String, dynamic> map, String field, String entity) {
  final value = map[field];
  if (value is! List) {
    throw FormatException('$entity.$field must be a list.');
  }
  return List<Object>.unmodifiable(value.cast<Object>());
}
