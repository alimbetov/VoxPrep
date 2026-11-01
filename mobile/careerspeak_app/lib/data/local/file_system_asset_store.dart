import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../application/content_delivery/content_manifest.dart';
import '../../application/ports/asset_cache_eviction_store.dart';
import '../../application/ports/asset_file_store.dart';
import '../../application/result/result.dart';

final class FileSystemAssetStore
    implements AssetFileStore, AssetCacheEvictionStore {
  FileSystemAssetStore(this._rootDirectory, {DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  final Directory _rootDirectory;
  final DateTime Function() _now;

  @override
  Future<Result<String?>> findVerified(ManifestAssetDescriptor asset) async {
    try {
      final file = _finalFile(asset);
      if (!await file.exists()) return const Success(null);
      if (await _isVerified(file, asset)) return Success(file.path);
      await file.delete();
      return const Success(null);
    } on FileSystemException catch (error) {
      return FailureResult(_fileFailure('ASSET_LOCAL_READ_FAILED', error));
    }
  }

  @override
  Future<Result<String>> writeVerified({
    required ManifestAssetDescriptor asset,
    required Stream<List<int>> bytes,
  }) async {
    final finalFile = _finalFile(asset);
    final parent = finalFile.parent;
    final tempFile = File(
      '${parent.path}/.${asset.checksumSha256}.${_now().microsecondsSinceEpoch}.part',
    );

    try {
      await parent.create(recursive: true);
      final sink = tempFile.openWrite();
      var size = 0;
      try {
        await for (final chunk in bytes) {
          size += chunk.length;
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      if (size != asset.sizeBytes) {
        await _deleteIfExists(tempFile);
        return FailureResult(
          ApplicationFailure(
            code: 'ASSET_SIZE_MISMATCH',
            message: 'Downloaded asset size does not match its manifest.',
            details: <String, Object?>{
              'assetId': asset.assetId,
              'expectedSize': asset.sizeBytes,
              'actualSize': size,
            },
          ),
        );
      }

      final digest = await sha256.bind(tempFile.openRead()).first;
      if (digest.toString() != asset.checksumSha256) {
        await _deleteIfExists(tempFile);
        return FailureResult(
          ApplicationFailure(
            code: 'ASSET_CHECKSUM_MISMATCH',
            message: 'Downloaded asset checksum does not match its manifest.',
            details: <String, Object?>{'assetId': asset.assetId},
          ),
        );
      }

      if (await finalFile.exists()) {
        if (await _isVerified(finalFile, asset)) {
          await _deleteIfExists(tempFile);
          return Success(finalFile.path);
        }
        await finalFile.delete();
      }

      await tempFile.rename(finalFile.path);
      return Success(finalFile.path);
    } on FileSystemException catch (error) {
      await _deleteIfExists(tempFile);
      return FailureResult(_fileFailure('ASSET_LOCAL_WRITE_FAILED', error));
    } catch (error) {
      await _deleteIfExists(tempFile);
      return FailureResult(
        ApplicationFailure(
          code: 'ASSET_STREAM_FAILED',
          message: 'The asset stream could not be written locally.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }

  @override
  Future<Result<bool>> evict(ManifestAssetDescriptor asset) async {
    try {
      final file = _finalFile(asset);
      if (!await file.exists()) return const Success(false);
      await file.delete();
      return const Success(true);
    } on FileSystemException catch (error) {
      return FailureResult(_fileFailure('ASSET_LOCAL_EVICTION_FAILED', error));
    }
  }

  File _finalFile(ManifestAssetDescriptor asset) {
    final extension = _extension(asset.deliveryKey);
    final fileName = extension == null
        ? asset.checksumSha256
        : '${asset.checksumSha256}.$extension';
    final prefix = asset.checksumSha256.substring(0, 2);
    return File('${_rootDirectory.path}/sha256/$prefix/$fileName');
  }

  Future<bool> _isVerified(File file, ManifestAssetDescriptor asset) async {
    if (await file.length() != asset.sizeBytes) return false;
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString() == asset.checksumSha256;
  }

  static String? _extension(String deliveryKey) {
    final fileName = deliveryKey.split('/').last;
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return null;
    final extension = fileName.substring(dot + 1).toLowerCase();
    return RegExp(r'^[a-z0-9]{1,10}$').hasMatch(extension) ? extension : null;
  }

  static Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Best-effort cleanup; the primary failure remains authoritative.
    }
  }

  static ApplicationFailure _fileFailure(
    String code,
    FileSystemException error,
  ) {
    return ApplicationFailure(
      code: code,
      message: 'Managed asset storage is temporarily unavailable.',
      retryable: true,
      details: <String, Object?>{'errorType': error.runtimeType.toString()},
    );
  }
}
