import 'package:flutter/services.dart';
import 'package:voip_call_engine_platform_interface/voip_call_engine_platform_interface.dart';

/// The Android implementation of [VoipCallEnginePlatform].
class VoipCallEngineAndroid extends MethodChannelVoipCallEngine {
  VoipCallEngineAndroid({super.methodChannel});

  /// Registers this class as the default instance of [VoipCallEnginePlatform] on Android.
  static void registerWith() {
    VoipCallEngineAndroid(
      methodChannel: const MethodChannel('dev.flutter.telecom/voip_call_engine'),
    )._setAsDefault();
  }

  void _setAsDefault() {
    VoipCallEnginePlatform.instance = this;
  }
}
