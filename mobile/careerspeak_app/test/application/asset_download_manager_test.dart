import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_byte_source.dart';
import 'package:careerspeak_app/application/ports/asset_file_store.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_download_manager.dart';
import 'package:flutter_test/flutter_test.dart';

const _checksum =
    '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';

void main() {
  test('reuses verified local asset without network', () async {
    final source = _FakeSource(<Result<AssetByteStream>>[]);
    final store = _FakeStore(findResult: const Success('/assets/hello.mp3'));
    final manager = AssetDownloadManager(source: source, store: store);

    final result = await manager.ensureLocal(_asset());

    final outcome = (result as Success<AssetDownloadOutcome>).value;
    expect(outcome.localPath, '/assets/hello.mp3');
    expect(outcome.reused, isTrue);
    expect(source.calls, 0);
    expect(store.writeCalls, 0);
  });

  test('retries retryable source failure and stores verified bytes', () async {
    final source = _FakeSource(<Result<AssetByteStream>>[
      const FailureResult(
        ApplicationFailure(
          code: 'ASSET_OFFLINE',
          message: 'offline',
          retryable: true,
        ),
      ),
      Success(
        AssetByteStream(
          bytes: Stream<List<int>>.value('hello'.codeUnits),
          contentLength: 5,
        ),
      ),
    ]);
    final store = _FakeStore(
      findResult: const Success(null),
      writeResult: const Success('/assets/hello.mp3'),
    );
    final manager = AssetDownloadManager(
      source: source,
      store: store,
      delay: (_) async {},
    );

    final result = await manager.ensureLocal(_asset());

    final outcome = (result as Success<AssetDownloadOutcome>).value;
    expect(outcome.reused, isFalse);
    expect(source.calls, 2);
    expect(store.writeCalls, 1);
  });

  test('rejects response size mismatch before writing', () async {
    final source = _FakeSource(<Result<AssetByteStream>>[
      Success(
        AssetByteStream(
          bytes: Stream<List<int>>.value('hello'.codeUnits),
          contentLength: 4,
        ),
      ),
    ]);
    final store = _FakeStore(findResult: const Success(null));
    final manager = AssetDownloadManager(source: source, store: store);

    final result = await manager.ensureLocal(_asset());

    expect(result, isA<FailureResult<AssetDownloadOutcome>>());
    expect(
      (result as FailureResult<AssetDownloadOutcome>).failure.code,
      'ASSET_SIZE_MISMATCH',
    );
    expect(store.writeCalls, 0);
  });
}

ManifestAssetDescriptor _asset() => ManifestAssetDescriptor(
  assetId: 'audio-hello',
  checksumSha256: _checksum,
  deliveryKey: 'audio/hello.mp3',
  sizeBytes: 5,
  mediaType: 'audio/mpeg',
  requiredOffline: false,
);

final class _FakeSource implements AssetByteSource {
  _FakeSource(this.results);

  final List<Result<AssetByteStream>> results;
  int calls = 0;

  @override
  Future<Result<AssetByteStream>> open(ManifestAssetDescriptor asset) async {
    final result = results[calls];
    calls += 1;
    return result;
  }
}

final class _FakeStore implements AssetFileStore {
  _FakeStore({required this.findResult, this.writeResult});

  final Result<String?> findResult;
  final Result<String>? writeResult;
  int writeCalls = 0;

  @override
  Future<Result<String?>> findVerified(ManifestAssetDescriptor asset) async =>
      findResult;

  @override
  Future<Result<String>> writeVerified({
    required ManifestAssetDescriptor asset,
    required Stream<List<int>> bytes,
  }) async {
    writeCalls += 1;
    return writeResult ??
        const FailureResult(
          ApplicationFailure(code: 'UNEXPECTED_WRITE', message: 'unexpected'),
        );
  }
}
