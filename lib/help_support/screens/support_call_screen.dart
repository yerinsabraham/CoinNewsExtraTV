import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/support_service.dart';

class SupportCallScreen extends StatefulWidget {
  final String callId;
  final String channelName;
  final String token;
  final bool isAdmin;

  const SupportCallScreen({
    super.key,
    required this.callId,
    required this.channelName,
    required this.token,
    this.isAdmin = false,
  });

  @override
  State<SupportCallScreen> createState() => _SupportCallScreenState();
}

class _SupportCallScreenState extends State<SupportCallScreen> {
  static const String appId = "YOUR_AGORA_APP_ID"; // TODO: Add your Agora App ID
  
  late RtcEngine _engine;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _speakerEnabled = true;
  Duration _callDuration = Duration.zero;
  late DateTime _callStartTime;

  @override
  void initState() {
    super.initState();
    _callStartTime = DateTime.now();
    initAgora();
  }

  Future<void> initAgora() async {
    // Request microphone permission
    await [Permission.microphone].request();

    // Create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          // TODO: Refresh token
        },
      ),
    );

    // Enable audio
    await _engine.enableAudio();
    
    // Set speaker as default
    await _engine.setDefaultAudioRouteToSpeakerphone(true);

    // Join channel
    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );

    // Start call duration timer
    _startCallTimer();
  }

  void _startCallTimer() {
    Stream.periodic(const Duration(seconds: 1)).listen((timer) {
      if (mounted) {
        setState(() {
          _callDuration = DateTime.now().difference(_callStartTime);
        });
      }
    });
  }

  Future<void> _onCallEnd() async {
    await _engine.leaveChannel();
    await _engine.release();
    
    // Update call status in Firestore
    await SupportService.endCall(widget.callId, _callDuration.inSeconds);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _onToggleMute() async {
    setState(() {
      _muted = !_muted;
    });
    await _engine.muteLocalAudioStream(_muted);
  }

  Future<void> _onSwitchSpeaker() async {
    setState(() {
      _speakerEnabled = !_speakerEnabled;
    });
    await _engine.setEnableSpeakerphone(_speakerEnabled);
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A1A),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(FeatherIcons.chevronLeft, color: Colors.white),
                        onPressed: _onCallEnd,
                      ),
                      const Spacer(),
                      Text(
                        widget.isAdmin ? 'Support Call' : 'CNETV Support',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40), // Balance the back button
                    ],
                  ),
                ),

                const Spacer(),

                // Call info section
                Column(
                  children: [
                    // Avatar
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF006833).withOpacity(0.3),
                        border: Border.all(
                          color: const Color(0xFF006833),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        FeatherIcons.headphones,
                        color: Color(0xFF006833),
                        size: 60,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Name
                    Text(
                      widget.isAdmin ? 'Support User' : 'CNETV Support Team',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Call status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _remoteUid != null 
                            ? const Color(0xFF006833).withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _remoteUid != null ? 'Connected' : 'Connecting...',
                        style: TextStyle(
                          color: _remoteUid != null ? const Color(0xFF006833) : Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Call duration
                    Text(
                      _formatDuration(_callDuration),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Control buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute button
                      _buildControlButton(
                        icon: _muted ? FeatherIcons.micOff : FeatherIcons.mic,
                        onPressed: _onToggleMute,
                        backgroundColor: _muted ? Colors.red : Colors.grey[800]!,
                        iconColor: Colors.white,
                      ),

                      // End call button
                      _buildControlButton(
                        icon: FeatherIcons.phoneOff,
                        onPressed: _onCallEnd,
                        backgroundColor: Colors.red,
                        iconColor: Colors.white,
                        size: 64,
                      ),

                      // Speaker button
                      _buildControlButton(
                        icon: _speakerEnabled ? FeatherIcons.volume2 : FeatherIcons.volumeX,
                        onPressed: _onSwitchSpeaker,
                        backgroundColor: _speakerEnabled 
                            ? const Color(0xFF006833) 
                            : Colors.grey[800]!,
                        iconColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
    double size = 56,
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
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: size * 0.4,
        ),
      ),
    );
  }
}