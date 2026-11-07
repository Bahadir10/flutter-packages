import 'package:flutter/services.dart';
import 'package:voip_call_engine_platform_interface/voip_call_engine_platform_interface.dart';

/// The iOS implementation of [VoipCallEnginePlatform].
class VoipCallEngineIos extends MethodChannelVoipCallEngine {
  VoipCallEngineIos({super.methodChannel});

  /// Registers this class as the default instance of [VoipCallEnginePlatform] on iOS.
  static void registerWith() {
    VoipCallEnginePlatform.instance = VoipCallEngineIos(
      methodChannel: const MethodChannel('dev.flutter.telecom/voip_call_engine'),
    );
  }
}
