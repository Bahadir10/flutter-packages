import 'package:flutter/services.dart';
import 'package:voip_call_engine_platform_interface/voip_call_engine_platform_interface.dart';

/// The Windows implementation of [VoipCallEnginePlatform].
class VoipCallEngineWindows extends MethodChannelVoipCallEngine {
  VoipCallEngineWindows({super.methodChannel});

  /// Registers this class as the default instance of [VoipCallEnginePlatform] on Windows.
  static void registerWith() {
    VoipCallEnginePlatform.instance = VoipCallEngineWindows(
      methodChannel: const MethodChannel('dev.flutter.telecom/voip_call_engine'),
    );
  }
}
