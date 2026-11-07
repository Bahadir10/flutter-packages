import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:voip_call_engine/voip_call_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoipShowcaseApp());
}

class VoipShowcaseApp extends StatelessWidget {
  const VoipShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoIP Call Engine Workbench',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0F766E),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const VoipWorkbenchScreen(),
    );
  }
}

class VoipWorkbenchScreen extends StatefulWidget {
  const VoipWorkbenchScreen({super.key});

  @override
  State<VoipWorkbenchScreen> createState() => _VoipWorkbenchScreenState();
}

class _VoipWorkbenchScreenState extends State<VoipWorkbenchScreen> {
  final VoipCallEngine _engine = VoipCallEngine.instance;
  final List<String> _logs = <String>[];
  StreamSubscription<CallEvent>? _eventSub;
  WebSocket? _harnessSocket;
  AudioRouteState _routeState = const AudioRouteState(
    activeRoute: AudioRoute.earpiece,
    availableRoutes: <AudioRoute>[
      AudioRoute.earpiece,
      AudioRoute.speaker,
      AudioRoute.bluetooth,
      AudioRoute.wiredHeadset,
    ],
  );
  bool _webrtcAudioEnabled = false;
  bool _harnessConnected = false;

  static const String _callId1 = '11111111-2222-4333-8444-555566667777';
  static const String _callId2 = '99999999-8888-4777-8666-555544443333';

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    _engine.audio.registerWebRtcHook((enabled) {
      if (!mounted) return;
      setState(() => _webrtcAudioEnabled = enabled);
      _appendLog('WebRTC Audio Barrier -> isAudioEnabled=$enabled');
    });

    _eventSub = _engine.events.listen((event) {
      if (!mounted) return;
      setState(() {});
      switch (event) {
        case CallIncomingReceived(:final request, :final reportedViaPushKit):
          _appendLog(
            'INCOMING: ${request.callerName} (${request.handle.value}) pushKit=$reportedViaPushKit',
          );
        case CallOutgoingStarted(:final request):
          _appendLog('OUTGOING: ${request.callerName}');
        case CallAnswered(:final callId, :final source):
          _appendLog('ANSWERED: $callId via ${source.name}');
        case CallStateTransitioned(:final session, :final previousState):
          _appendLog(
            'STATE [${session.callerName}]: ${previousState.name} -> ${session.state.name}',
          );
        case CallHeldChanged(:final callId, :final isOnHold, :final heldBySystem):
          _appendLog(
            'HOLD: $callId onHold=$isOnHold (bySystem=$heldBySystem)',
          );
        case CallMutedChanged(:final callId, :final isMuted):
          _appendLog('MUTE: $callId muted=$isMuted');
        case CallAudioSessionActivationChanged(:final isActive):
          _appendLog('NATIVE AUDIO SESSION: active=$isActive');
        case CallAudioRouteChanged(:final routeState, :final reason):
          setState(() => _routeState = routeState);
          _appendLog(
            'AUDIO ROUTE: ${routeState.activeRoute.name} ($reason)',
          );
        case CallEnded(:final callId, :final reason):
          _appendLog('ENDED: $callId reason=${reason.name}');
        case VoipPushTokenUpdated(:final token, :final environment):
          _appendLog('PUSH TOKEN ($environment): $token');
        case CallDtmfTonePlayed(:final callId, :final digits):
          _appendLog('DTMF [$callId]: $digits');
        case CallDiagnosticEvent(:final code, :final message):
          _appendLog('DIAG [$code]: $message');
      }
    });

    final coldStartEvents = await _engine.initialize(
      const VoipEngineConfig(
        ios: IosCallConfig(appName: 'Telecom Pro'),
        android: AndroidCallConfig(phoneAccountLabel: 'Telecom Pro VoIP'),
      ),
    );
    if (coldStartEvents.isNotEmpty) {
      _appendLog('Replayed ${coldStartEvents.length} cold-start native events.');
    }
    final route = await _engine.audio.getRouteState();
    if (mounted) {
      setState(() => _routeState = route);
    }
  }

  void _appendLog(String line) {
    final now = DateTime.now().toIso8601String().substring(11, 23);
    setState(() {
      _logs.insert(0, '[$now] $line');
      if (_logs.length > 80) _logs.removeLast();
    });
  }

  Future<void> _connectGoHarness() async {
    try {
      await _harnessSocket?.close();
      // ignore: close_sinks
      final ws = await WebSocket.connect('ws://127.0.0.1:8090/ws');
      _harnessSocket = ws;
      setState(() => _harnessConnected = true);
      _appendLog('Connected to Go VoIP Test Harness (ws://127.0.0.1:8090/ws)');
      ws.listen(
        (dynamic raw) async {
          final map = jsonDecode(raw as String) as Map<String, dynamic>;
          final type = map['type'] as String? ?? '';
          if (type == 'incoming_call') {
            await _engine.reportIncomingCall(
              CallRequest(
                callId: map['callId'] as String? ?? _callId1,
                callerName: map['callerName'] as String? ?? 'Go Bot Caller',
                handle: CallHandle(
                  type: CallHandleType.phoneNumber,
                  value: map['handle'] as String? ?? '+905550009988',
                ),
              ),
            );
          } else if (type == 'remote_hangup') {
            final callId = map['callId'] as String? ?? _callId1;
            await _engine.endCall(callId, reason: CallEndReason.remoteHangup);
          }
        },
        onDone: () => setState(() => _harnessConnected = false),
        onError: (_) => setState(() => _harnessConnected = false),
      );
    } catch (e) {
      _appendLog('Go Harness connection error: $e');
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _harnessSocket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCalls = _engine.activeCalls.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('VoIP Call Lifecycle & Audio Workbench'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Chip(
              avatar: Icon(
                _webrtcAudioEnabled ? Icons.graphic_eq : Icons.mic_off,
                size: 18,
                color: _webrtcAudioEnabled ? Colors.greenAccent : Colors.amber,
              ),
              label: Text(
                _webrtcAudioEnabled ? 'WebRTC Audio Ready' : 'Audio Barrier Locked',
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildSimulationControls(),
          const SizedBox(height: 16),
          _buildAudioRouterCard(),
          const SizedBox(height: 16),
          _buildActiveCallsSection(activeCalls),
          const SizedBox(height: 16),
          _buildEventLogCard(),
        ],
      ),
    );
  }

  Widget _buildSimulationControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '1. Call Lifecycle & Multi-Call Simulation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: () => _engine.reportIncomingCall(
                    const CallRequest(
                      callId: _callId1,
                      callerName: 'Alice Yılmaz (Line 1)',
                      handle: CallHandle(
                        type: CallHandleType.phoneNumber,
                        value: '+90 532 111 22 33',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.call_received),
                  label: const Text('Incoming Call #1'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _engine.reportIncomingCall(
                    const CallRequest(
                      callId: _callId2,
                      callerName: 'Bob Kaya (Line 2 - Call Waiting)',
                      handle: CallHandle(
                        type: CallHandleType.phoneNumber,
                        value: '+90 544 999 88 77',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add_ic_call),
                  label: const Text('Incoming Call #2 (Waiting)'),
                ),
                OutlinedButton.icon(
                  onPressed: _harnessConnected ? null : _connectGoHarness,
                  icon: Icon(_harnessConnected ? Icons.cloud_done : Icons.bolt),
                  label: Text(
                    _harnessConnected ? 'Go Harness Connected' : 'Connect Go Harness',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioRouterCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '2. Telecom Audio Router (Active: ${_routeState.activeRoute.name.toUpperCase()})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: AudioRoute.values.map((route) {
                final selected = _routeState.activeRoute == route;
                return ChoiceChip(
                  label: Text(route.name),
                  selected: selected,
                  onSelected: (_) => _engine.audio.setRoute(route),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCallsSection(List<CallSession> calls) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '3. Active Sessions (${calls.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (calls.isEmpty)
              const Text('No active calls. Trigger an incoming or outgoing call above.')
            else
              ...calls.map((session) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${session.callerName} — ${session.state.name.toUpperCase()}'),
                    subtitle: Text(
                      'ID: ${session.callId.substring(0, 8)}... | '
                      'Hold: ${session.isOnHold} | Muted: ${session.isMuted} | '
                      'AudioActive: ${session.audioSessionActive}',
                    ),
                    trailing: Wrap(
                      spacing: 6,
                      children: <Widget>[
                        if (session.state == CallState.incomingRinging)
                          IconButton.filled(
                            tooltip: 'Answer & Connect Media',
                            onPressed: () async {
                              await _engine.answerCall(session.callId);
                              await _engine.reportCallConnected(session.callId);
                            },
                            icon: const Icon(Icons.call),
                          ),
                        if (session.state == CallState.active ||
                            session.state == CallState.onHold)
                          IconButton.outlined(
                            tooltip: 'Toggle Hold',
                            onPressed: () => _engine.setHold(
                              session.callId,
                              isOnHold: !session.isOnHold,
                            ),
                            icon: Icon(
                              session.isOnHold ? Icons.play_arrow : Icons.pause,
                            ),
                          ),
                        IconButton.filledTonal(
                          tooltip: 'End Call',
                          onPressed: () => _engine.endCall(session.callId),
                          icon: const Icon(Icons.call_end, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildEventLogCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '4. Deterministic Event Stream & Diagnostics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 220,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) => Text(
                  _logs[index],
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
