from pathlib import Path

path = Path('mobile/careerspeak_app/test/acceptance/c1_online_sync_offline_reopen_acceptance_test.dart')
text = path.read_text()
text = text.replace(
    '          localizedPayloadGateway: backend,',
    '          localizedPayloadGateway: _LocalizedGateway(backend),',
    1,
)
text = text.replace(
    '''final class _BackendFixture
    implements
        ContentManifestGateway,
        ContentPayloadGateway,
        LocalizedContentPayloadGateway {''',
    '''final class _BackendFixture implements ContentManifestGateway, ContentPayloadGateway {''',
    1,
)
old = '''
  @override
  Future<Result<LocalizedContentPayload>> fetchLocalized(
    LocalizedContentRef target,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<LocalizedContentPayload>> fetch(LocalizedContentRef target) async {
    localizedPayloadCalls += 1;
    return Success<LocalizedContentPayload>(
      LocalizedContentPayload(
        ref: localizedRef,
        title: 'Русский заголовок',
        translation: 'Русский перевод',
      ),
    );
  }
}

const _identity ='''
new = '''
}

final class _LocalizedGateway implements LocalizedContentPayloadGateway {
  const _LocalizedGateway(this.backend);

  final _BackendFixture backend;

  @override
  Future<Result<LocalizedContentPayload>> fetch(LocalizedContentRef target) async {
    backend.localizedPayloadCalls += 1;
    return Success<LocalizedContentPayload>(
      LocalizedContentPayload(
        ref: backend.localizedRef,
        title: 'Русский заголовок',
        translation: 'Русский перевод',
      ),
    );
  }
}

const _identity ='''
if new not in text:
    if old not in text:
        raise SystemExit('missing C1 online/offline gateway split anchor')
    text = text.replace(old, new, 1)
path.write_text(text)
