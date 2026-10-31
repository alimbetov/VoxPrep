import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/data/mock/demo_vertical_catalogue_fixture.dart';
import 'package:careerspeak_app/data/remote/vertical_catalogue_bundle_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo backend publishes eight verticals grouped into shelves', () {
    final payloads = buildDemoVerticalCataloguePayloads();
    const decoder = VerticalCatalogueBundleDecoder();

    final sections = payloads.values.singleWhere(
      (payload) => payload.ref.kind == CatalogueKind.verticalSections,
    );
    final verticals = payloads.values.singleWhere(
      (payload) => payload.ref.kind == CatalogueKind.verticals,
    );
    final presentation = payloads.values.singleWhere(
      (payload) => payload.ref.kind == CatalogueKind.verticalPresentation,
    );

    final bundle = decoder.decode(
      sectionsPayload: sections,
      verticalsPayload: verticals,
      presentationPayload: presentation,
    );

    expect(bundle.verticals, hasLength(8));
    expect(bundle.sections, hasLength(3));
    expect(bundle.presentation.showSeeAll, isTrue);
    expect(
      bundle.verticals.map((vertical) => vertical.code),
      containsAll(<String>[
        'JAVA_INTERVIEW',
        'QA_INTERVIEW',
        'DEVOPS_INTERVIEW',
        'AWS',
        'KUBERNETES',
        'MEDICAL_ENGLISH',
        'SALES_ENGLISH',
        'BANKING_ENGLISH',
      ]),
    );
  });
}
