import '../../application/ports/locale_configuration_gateway.dart';
import '../../domain/locale_configuration.dart';
import 'package:flutter/services.dart';

import '../../application/content_delivery/content_manifest.dart';
import '../../application/ports/asset_byte_source.dart';
import '../../application/ports/installation_credential_store.dart';
import '../../application/result/result.dart';
import '../../domain/installation_credentials.dart';

/// Only composed by main_demo; no server credentials or remote storage access.
final class DemoAssetByteSource implements AssetByteSource {
  @override
  Future<Result<AssetByteStream>> open(ManifestAssetDescriptor asset) async {
    final path = switch (asset.assetId) {
      'demo-java-cover' => 'assets/demo/java-cover.png',
      'demo-medical-cover' => 'assets/demo/medical-cover.png',
      'demo-communication-cover' => 'assets/demo/communication-cover.png',
      'demo-speaking-audio' => 'assets/demo/speaking-sample.mp3',
      'demo-catalogue-icon' => 'assets/demo/catalogue-icon.png',
      _ => null,
    };
    if (path == null) {
      return const FailureResult(
        ApplicationFailure(
          code: 'DEMO_ASSET_MISSING',
          message: 'No bundled demo asset.',
        ),
      );
    }
    final data = await rootBundle.load(path);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return Success(
      AssetByteStream(bytes: Stream.value(bytes), contentLength: bytes.length),
    );
  }
}

final class DemoCredentialStore implements InstallationCredentialStore {
  InstallationId? id;
  InstallationToken? token;
  @override
  Future<InstallationId?> readInstallationId() async => id;
  @override
  Future<InstallationToken?> readInstallationToken() async => token;
  @override
  Future<void> writeInstallationId(InstallationId value) async {
    id = value;
  }

  @override
  Future<void> writeInstallationToken(InstallationToken value) async {
    token = value;
  }

  @override
  Future<void> clearInstallationToken() async {
    token = null;
  }

  @override
  Future<void> clear() async {
    id = null;
    token = null;
  }
}

final class DemoLocaleConfigurationGateway
    implements LocaleConfigurationGateway {
  @override
  Future<Result<CountryLocaleConfiguration>> fetchForCountry(
    String countryCode,
  ) async => Success(
    CountryLocaleConfiguration(
      countryCode: countryCode,
      defaultLocale: 'en',
      locales: [
        SupportedLocaleOption(code: 'en', label: 'English'),
        SupportedLocaleOption(code: 'ru', label: 'Русский'),
        SupportedLocaleOption(code: 'kk', label: 'Қазақша'),
      ],
    ),
  );
}
