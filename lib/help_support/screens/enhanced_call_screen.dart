import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/support_service.dart';

class EnhancedCallScreen extends StatefulWidget {
  final String callId;
  final String? channelName;
  final String? token;
  final bool isAdmin;
  final String callerName;
  final String? callerAvatar;

  const EnhancedCallScreen({
    super.key,
    required this.callId,
    this.channelName,
    this.token,
    this.isAdmin = false,
    required this.callerName,
    this.callerAvatar,
  });

  @override
  State<EnhancedCallScreen> createState() => _EnhancedCallScreenState();
}

class _EnhancedCallScreenState extends State<EnhancedCallScreen>
    with TickerProviderStateMixin {
  bool _isConnected = false;
  bool _muted = false;
  bool _speakerEnabled = true;
  Duration _callDuration = Duration.zero;
  Timer? _callTimer;
  Timer? _timeoutTimer;
  // Agora engine (optional) - initialized when channel/token provided
  late RtcEngine _engine;
  bool _agoraInitialized = false;
  late AnimationController _pulseController;
  late AnimationController _connectingController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _connectingAnimation;
  
  // Call states
  CallState _currentState = CallState.dialing;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeCall();
    // If channel and token are provided up-front, initialize Agora
    if (widget.channelName != null) {
      if (widget.token != null) {
        _initAgora();
      } else {
        // Try to fetch token from serverless endpoint (if available)
        _fetchAgoraTokenAndInit();
      }
    }
  }

  static const String _agoraAppId = "YOUR_AGORA_APP_ID"; // replace with real app id

  Future<void> _initAgora() async {
    try {
      await [Permission.microphone].request();

      _engine = createAgoraRtcEngine();
      await _engine.initialize(const RtcEngineContext(
        appId: _agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _isConnected = true;
            _agoraInitialized = true;
          });
          _startCallTimer();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          // remote joined
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          // remote left
        },
      ));

      await _engine.enableAudio();
      await _engine.setDefaultAudioRouteToSpeakerphone(true);

      if (widget.token != null && widget.channelName != null) {
        await _engine.joinChannel(
          token: widget.token!,
          channelId: widget.channelName!,
          uid: 0,
          options: const ChannelMediaOptions(),
        );
      }
    } catch (e) {
      // silently ignore agora init failures (UI still works in simulated mode)
      print('Agora init error: $e');
    }
  }

  // Replace with your deployed functions URL if different
  static const String _generateTokenUrl = 'https://us-central1-coinnewsextratv-9c75a.cloudfunctions.net/generateAgoraToken';

  Future<void> _fetchAgoraTokenAndInit() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // can't fetch token if not authenticated

      final idToken = await user.getIdToken();

      final resp = await http.post(
        Uri.parse(_generateTokenUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'channel': widget.channelName,
          'uid': 0,
          'role': 'publisher',
          'ttl': 3600,
        }),
      ).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final token = data['token'] as String?;
        final returnedAppId = data['appId'] as String?;
        if (token != null && mounted) {
          final fetchedToken = token;
          // initialize agora with the fetched token and server-provided appId if present
          await _initAgoraWithToken(fetchedToken, returnedAppId);
        }
      } else {
        print('Failed to fetch Agora token: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      print('Error fetching Agora token: $e');
    }
  }

  Future<void> _initAgoraWithToken(String token, [String? appIdOverride]) async {
    try {
      await [Permission.microphone].request();

      _engine = createAgoraRtcEngine();
      final appIdToUse = (appIdOverride != null && appIdOverride.isNotEmpty) ? appIdOverride : _agoraAppId;
      await _engine.initialize(RtcEngineContext(
        appId: appIdToUse,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _isConnected = true;
            _agoraInitialized = true;
          });
          _startCallTimer();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {},
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {},
      ));

      await _engine.enableAudio();
      await _engine.setDefaultAudioRouteToSpeakerphone(true);

      if (widget.channelName != null) {
        await _engine.joinChannel(
          token: token,
          channelId: widget.channelName!,
          uid: 0,
          options: const ChannelMediaOptions(),
        );
      }
    } catch (e) {
      print('Agora init error with fetched token: $e');
    }
  }

  void _setupAnimations() {
    // Pulse animation for ringing state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Connecting animation
    _connectingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _connectingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _connectingController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  void _initializeCall() {
    if (widget.isAdmin) {
      // Admin is receiving a call
      _currentState = CallState.incoming;
    } else {
      // User is making a call
      _currentState = CallState.dialing;
      _startTimeoutTimer();
    }
    setState(() {});
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (_currentState != CallState.connected) {
        _handleCallTimeout();
      }
    });
  }

  void _handleCallTimeout() {
    setState(() {
      _currentState = CallState.noAnswer;
    });
    _pulseController.stop();
    _connectingController.stop();
    
    // Auto close after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _endCall();
      }
    });
  }

  void _acceptCall() {
    setState(() {
      _currentState = CallState.connecting;
    });
    _connectingController.repeat();
    _pulseController.stop();
    
    // Simulate connection process
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentState = CallState.connected;
          _isConnected = true;
        });
        _connectingController.stop();
        _startCallTimer();
      }
    });
  }

  void _rejectCall() {
    _endCall();
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration = Duration(seconds: timer.tick);
        });
      }
    });
  }

  Future<void> _toggleMute() async {
    setState(() {
      _muted = !_muted;
    });
    try {
      if (_agoraInitialized) {
        await _engine.muteLocalAudioStream(_muted);
      } else {
        // no-op: simulated mute state only
      }
    } catch (e) {
      print('Error toggling mute: $e');
    }
  }

  Future<void> _toggleSpeaker() async {
    setState(() {
      _speakerEnabled = !_speakerEnabled;
    });
    try {
      if (_agoraInitialized) {
        await _engine.setEnableSpeakerphone(_speakerEnabled);
      } else {
        // no-op: simulated speaker toggle only
      }
    } catch (e) {
      print('Error toggling speaker: $e');
    }
  }

  Future<void> _endCall() async {
    _timeoutTimer?.cancel();
    _callTimer?.cancel();
    _pulseController.stop();
    _connectingController.stop();
    
    try {
      if (_isConnected) {
        await SupportService.endCall(widget.callId, _callDuration.inSeconds);
      }
    } catch (e) {
      print('Error ending call: $e');
    }
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _callTimer?.cancel();
    _pulseController.dispose();
    _connectingController.dispose();
    if (_agoraInitialized) {
      try {
        _engine.leaveChannel();
        _engine.release();
      } catch (_) {}
    }
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  _getStateColor().withOpacity(0.1),
                  Colors.black,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                const Spacer(),
                
                // Main call interface
                _buildCallInterface(),
                
                const Spacer(),
                
                // Controls
                _buildControls(),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentState == CallState.connected)
            IconButton(
              icon: const Icon(FeatherIcons.chevronDown, color: Colors.white, size: 28),
              onPressed: () {
                // Minimize call (keep in background)
                Navigator.pop(context);
              },
            ),
          const Spacer(),
          Text(
            _getHeaderTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: 'Lato',
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the minimize button
        ],
      ),
    );
  }

  Widget _buildCallInterface() {
    return Column(
      children: [
        // Avatar with animation
        AnimatedBuilder(
          animation: _currentState == CallState.dialing || _currentState == CallState.incoming
              ? _pulseAnimation
              : _connectingAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _currentState == CallState.dialing || _currentState == CallState.incoming
                  ? _pulseAnimation.value
                  : 1.0,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStateColor().withOpacity(0.2),
                  border: Border.all(
                    color: _getStateColor(),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getStateColor().withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: widget.callerAvatar != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(80),
                        child: Image.network(
                          widget.callerAvatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                        ),
                      )
                    : _buildDefaultAvatar(),
              ),
            );
          },
        ),
        
        const SizedBox(height: 32),
        
        // Name
        Text(
          widget.callerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        // Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getStateColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStateColor(),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Lato',
            ),
          ),
        ),
        
        if (_currentState == CallState.connected) ...[
          const SizedBox(height: 16),
          Text(
            _formatDuration(_callDuration),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      widget.isAdmin ? FeatherIcons.user : FeatherIcons.headphones,
      color: _getStateColor(),
      size: 80,
    );
  }

  Widget _buildControls() {
    switch (_currentState) {
      case CallState.incoming:
        return _buildIncomingControls();
      case CallState.dialing:
      case CallState.connecting:
        return _buildDialingControls();
      case CallState.connected:
        return _buildConnectedControls();
      case CallState.noAnswer:
        return _buildNoAnswerControls();
    }
  }

  Widget _buildIncomingControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reject button
          _buildControlButton(
            icon: FeatherIcons.phoneOff,
            onPressed: _rejectCall,
            backgroundColor: Colors.red,
            size: 70,
          ),
          
          // Accept button
          _buildControlButton(
            icon: FeatherIcons.phone,
            onPressed: _acceptCall,
            backgroundColor: Colors.green,
            size: 70,
          ),
        ],
      ),
    );
  }

  Widget _buildDialingControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // End call button
          _buildControlButton(
            icon: FeatherIcons.phoneOff,
            onPressed: _endCall,
            backgroundColor: Colors.red,
            size: 70,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _muted ? FeatherIcons.micOff : FeatherIcons.mic,
            onPressed: _toggleMute,
            backgroundColor: _muted ? Colors.red : Colors.grey[800]!,
            size: 60,
          ),
          
          // End call button
          _buildControlButton(
            icon: FeatherIcons.phoneOff,
            onPressed: _endCall,
            backgroundColor: Colors.red,
            size: 70,
          ),
          
          // Speaker button
          _buildControlButton(
            icon: _speakerEnabled ? FeatherIcons.volume2 : FeatherIcons.volumeX,
            onPressed: _toggleSpeaker,
            backgroundColor: _speakerEnabled ? Colors.blue : Colors.grey[800]!,
            size: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildNoAnswerControls() {
    return Column(
      children: [
        const Text(
          'Try again later or send a message',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontFamily: 'Lato',
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _endCall,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text(
            'Close',
            style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.35,
        ),
      ),
    );
  }

  Color _getStateColor() {
    switch (_currentState) {
      case CallState.incoming:
      case CallState.connected:
        return const Color(0xFF006833);
      case CallState.dialing:
      case CallState.connecting:
        return Colors.blue;
      case CallState.noAnswer:
        return Colors.orange;
    }
  }

  String _getHeaderTitle() {
    switch (_currentState) {
      case CallState.incoming:
        return 'Incoming Call';
      case CallState.dialing:
        return 'Calling...';
      case CallState.connecting:
        return 'Connecting...';
      case CallState.connected:
        return 'CNETV Support';
      case CallState.noAnswer:
        return 'Call Ended';
    }
  }

  String _getStatusText() {
    switch (_currentState) {
      case CallState.incoming:
        return 'Incoming call from support';
      case CallState.dialing:
        return 'Calling CNETV Support...';
      case CallState.connecting:
        return 'Connecting...';
      case CallState.connected:
        return 'Connected';
      case CallState.noAnswer:
        return 'Support Team is not available right now';
    }
  }
}

enum CallState {
  incoming,
  dialing,
  connecting,
  connected,
  noAnswer,
}