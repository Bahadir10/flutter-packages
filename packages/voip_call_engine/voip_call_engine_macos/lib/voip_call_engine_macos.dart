import 'package:flutter/services.dart';
import 'package:voip_call_engine_platform_interface/voip_call_engine_platform_interface.dart';

/// The macOS implementation of [VoipCallEnginePlatform].
class VoipCallEngineMacos extends MethodChannelVoipCallEngine {
  VoipCallEngineMacos({super.methodChannel});

  /// Registers this class as the default instance of [VoipCallEnginePlatform] on macOS.
  static void registerWith() {
    VoipCallEnginePlatform.instance = VoipCallEngineMacos(
      methodChannel: const MethodChannel('dev.flutter.telecom/voip_call_engine'),
    );
  }
}
