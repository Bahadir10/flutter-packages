# Flutter Telecom & Native Enterprise Packages Monorepo

Production-grade Flutter federated plugins for **VoIP Call Lifecycle (`CallKit` + `ConnectionService`)**, **Telecom Audio Routing (`AVAudioSession` + `AudioManager` + `WASAPI` + `CoreAudio`)**, **eSIM Provisioning (`CTCellularPlanProvisioning` + `EuiccManager`)**, and **Native Telecom Capabilities**, paired with a **Go (Golang) Test & Acoustic DSP Harness**.

## Packages in this Monorepo

| Package | Description | Platforms |
| :--- | :--- | :--- |
| [`voip_call_engine`](./packages/voip_call_engine/voip_call_engine) | Deterministic VoIP Call Lifecycle, CallKit, ConnectionService, Multi-Call Hold/Swap, and WebRTC Audio Barrier Engine. | iOS, Android, Windows, macOS, Web |
| [`voip_call_engine_platform_interface`](./packages/voip_call_engine/voip_call_engine_platform_interface) | Common platform interface, 5-invariant `CallStateMachine`, Tombstone cache, Watchdogs, and models. | All |
| [`voip_call_engine_ios`](./packages/voip_call_engine/voip_call_engine_ios) | Swift `PKPushRegistry` (Zero-Crash iOS 13+), `CXProvider`, `AVAudioSession`, and `NativeEventRingBuffer`. | iOS |
| [`voip_call_engine_android`](./packages/voip_call_engine/voip_call_engine_android) | Kotlin Self-Managed `ConnectionService`, GSM hold detection, and `AudioManager` (`setCommunicationDevice` / BT SCO). | Android |
| [`voip_call_engine_windows`](./packages/voip_call_engine/voip_call_engine_windows) | C++ Windows `WASAPI` (`IMMDeviceEnumerator`) audio routing and desktop call management. | Windows |
| [`voip_call_engine_macos`](./packages/voip_call_engine/voip_call_engine_macos) | Swift macOS `CoreAudio` (`AudioObjectGetPropertyData`) and `CallKit` integration. | macOS |
| [`voip_call_engine_web`](./packages/voip_call_engine/voip_call_engine_web) | Web audio sink routing and browser call notifications. | Web |

## Go Test & Acoustic DSP Harness (`tools/go_voip_harness`)

Located in [`tools/go_voip_harness`](./tools/go_voip_harness), the Go harness provides:
- **APNs HTTP/2 VoIP Push Envelope Generator**
- **WebSocket Bidirectional Signaling & `fe_ack` Telemetry Verifier**
- **Goertzel 440Hz Acoustic DSP Analyzer** (`AnalyzePCM16Audio`)
- **Zero-Touch E2E Integration** (`fe_be_zero_touch_e2e_test.dart`)

## Running Tests

```bash
# 1. Run static analysis across all workspace packages
dart analyze

# 2. Run all Flutter unit, 10,000-step Chaos/Fuzz, Widget, and Zero-Touch Go BE <-> Flutter FE E2E tests
flutter test packages/voip_call_engine/voip_call_engine_platform_interface \
             packages/voip_call_engine/voip_call_engine \
             packages/voip_call_engine/voip_call_engine/example \
             examples/voip_showcase_app

# 3. Run Go DSP & Concurrent WebSocket Stress tests
cd tools/go_voip_harness && go test -v ./...
```
