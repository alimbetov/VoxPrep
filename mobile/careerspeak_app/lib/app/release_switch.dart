import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppRunMode { development, release }

final class AppRunModePolicy {
  const AppRunModePolicy._();

  static AppRunMode resolve({
    required bool compilerReleaseMode,
    required bool releaseFlagEnabled,
  }) {
    return compilerReleaseMode || releaseFlagEnabled
        ? AppRunMode.release
        : AppRunMode.development;
  }
}

const _releaseFlagEnabled = bool.fromEnvironment(
  'VOXPREP_RELEASE',
  defaultValue: false,
);

final appRunModeProvider = Provider<AppRunMode>((ref) {
  return AppRunModePolicy.resolve(
    compilerReleaseMode: kReleaseMode,
    releaseFlagEnabled: _releaseFlagEnabled,
  );
});

extension AppRunModeX on AppRunMode {
  bool get isRelease => this == AppRunMode.release;
  bool get isDevelopment => this == AppRunMode.development;
}
