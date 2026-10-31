import 'package:careerspeak_app/application/content_delivery/catalogue_payload.dart';
import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/application/content_delivery/vertical_catalogue_presentation.dart';
import 'package:careerspeak_app/data/remote/vertical_catalogue_bundle_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('decodes backend-owned sections, verticals and presentation', () {
    const decoder = VerticalCatalogueBundleDecoder();

    final bundle = decoder.decode(
      sectionsPayload: _payload(
        CatalogueKind.verticalSections,
        <Object>[
          <String, dynamic>{
            'code': 'SOFTWARE_ENGINEERING',
            'title': 'Software Engineering',
            'sortOrder': 0,
            'active': true,
          },
        ],
      ),
      verticalsPayload: _payload(
        CatalogueKind.verticals,
        <Object>[
          <String, dynamic>{
            'code': 'JAVA_INTERVIEW',
            'sectionCode': 'SOFTWARE_ENGINEERING',
            'title': 'Java Interview',
            'description': 'Java interview communication',
            'iconAssetId': 'asset-java',
            'sortOrder': 0,
            'active': true,
          },
        ],
      ),
      presentationPayload: _payload(
        CatalogueKind.verticalPresentation,
        <Object>[
          <String, dynamic>{
            'mode': 'SHELVES',
            'showFeatured': false,
            'showSeeAll': true,
            'featuredSectionCode': null,
          },
        ],
      ),
    );

    expect(bundle.sections.single.code, 'SOFTWARE_ENGINEERING');
    expect(bundle.verticals.single.code, 'JAVA_INTERVIEW');
    expect(bundle.presentation.mode, VerticalCataloguePresentationMode.shelves);
  });

  test('rejects presentation catalogue with more than one config item', () {
    const decoder = VerticalCatalogueBundleDecoder();
    final config = <String, dynamic>{
      'mode': 'CAROUSEL',
      'showFeatured': false,
      'showSeeAll': true,
      'featuredSectionCode': null,
    };

    expect(
      () => decoder.decode(
        sectionsPayload: _payload(
          CatalogueKind.verticalSections,
          const <Object>[],
        ),
        verticalsPayload: _payload(CatalogueKind.verticals, const <Object>[]),
        presentationPayload: _payload(
          CatalogueKind.verticalPresentation,
          <Object>[config, config],
        ),
      ),
      throwsFormatException,
    );
  });

  test('rejects accidental catalogue kind substitution', () {
    const decoder = VerticalCatalogueBundleDecoder();

    expect(
      () => decoder.decode(
        sectionsPayload: _payload(CatalogueKind.verticals, const <Object>[]),
        verticalsPayload: _payload(CatalogueKind.verticals, const <Object>[]),
        presentationPayload: _payload(
          CatalogueKind.verticalPresentation,
          <Object>[
            <String, dynamic>{
              'mode': 'GRID',
              'showFeatured': false,
              'showSeeAll': false,
              'featuredSectionCode': null,
            },
          ],
        ),
      ),
      throwsFormatException,
    );
  });
}

CataloguePayload _payload(CatalogueKind kind, List<Object> items) {
  final ref = CatalogueRevisionRef(
    kind: kind,
    revision: 1,
    checksum: _hash,
  );
  return CataloguePayload(
    ref: ref,
    items: items,
    wireJson: <String, Object?>{
      'kind': kind.wireName,
      'revision': 1,
      'checksum': _hash,
      'items': items,
    },
  );
}
