import 'package:flutter/foundation.dart';

/// Deriva do alvo de compilação (Windows/Linux/macOS = desktop; Android/iOS = mobile).
bool get isDesktopFormFactor {
  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
      return true;
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      return false;
  }
}

bool get isMobileFormFactor => !isDesktopFormFactor;
