import '../../application/content_delivery/catalogue_payload.dart';
import '../../application/content_delivery/catalogue_revision_ref.dart';
import '../../application/content_delivery/learning_vertical.dart';
import '../../application/content_delivery/vertical_catalogue_presentation.dart';
import 'learning_vertical_decoder.dart';
import 'vertical_catalogue_presentation_decoder.dart';

final class VerticalCatalogueBundle {
  const VerticalCatalogueBundle({
    required this.sections,
    required this.verticals,
    required this.presentation,
  });

  final List<VerticalSectionProjection> sections;
  final List<LearningVerticalProjection> verticals;
  final VerticalCataloguePresentation presentation;
}

final class VerticalCatalogueBundleDecoder {
  const VerticalCatalogueBundleDecoder({
    this.verticalDecoder = const LearningVerticalDecoder(),
    this.presentationDecoder = const VerticalCataloguePresentationDecoder(),
  });

  final LearningVerticalDecoder verticalDecoder;
  final VerticalCataloguePresentationDecoder presentationDecoder;

  VerticalCatalogueBundle decode({
    required CataloguePayload sectionsPayload,
    required CataloguePayload verticalsPayload,
    required CataloguePayload presentationPayload,
  }) {
    _requireKind(sectionsPayload, CatalogueKind.verticalSections);
    _requireKind(verticalsPayload, CatalogueKind.verticals);
    _requireKind(presentationPayload, CatalogueKind.verticalPresentation);

    if (presentationPayload.items.length != 1) {
      throw const FormatException(
        'Vertical presentation catalogue must contain exactly one item.',
      );
    }

    return VerticalCatalogueBundle(
      sections: presentationDecoder.decodeSections(sectionsPayload.items),
      verticals: verticalDecoder.decodeAll(verticalsPayload.items),
      presentation: presentationDecoder.decodePresentation(
        presentationPayload.items.single,
      ),
    );
  }
}

void _requireKind(CataloguePayload payload, CatalogueKind expected) {
  if (payload.ref.kind != expected) {
    throw FormatException(
      'Expected ${expected.wireName} catalogue, got ${payload.ref.kind.wireName}.',
    );
  }
}
