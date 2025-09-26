import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/video_model.dart';
import '../provider/user_provider.dart';
import '../services/video_service.dart';

class VideoScreen extends StatefulWidget {
  final VideoModel video;
  const VideoScreen({super.key, required this.video});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late YoutubePlayerController _controller;
  bool _rewarded = false;
  final double rewardAmount = 1.0; // example: 1 point per full video

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    )..addListener(_listener);
  }

  void _listener() {
    final playerState = _controller.value.playerState;
    if (playerState == PlayerState.ended && !_rewarded) {
      _rewarded = true;
      _onVideoCompleted();
    }
  }

  Future<void> _onVideoCompleted() async {
    final userProv = Provider.of<UserProvider>(context, listen: false);
    if (!userProv.isLoggedIn || userProv.user == null) {
      // show sign-in prompt — guest watched but must sign in to collect reward
      _showSignInRequiredDialog();
      return;
    }
    final uid = userProv.user!.uid;
    final success = await VideoService.awardReward(
      uid: uid,
      videoId: widget.video.id,
      rewardAmount: rewardAmount,
    );
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You earned $rewardAmount points!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reward already claimed for this video.')),
        );
      }
    }
  }

  void _showSignInRequiredDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign in to collect rewards'),
        content: const Text(
            'You watched the video — sign in to claim your reward for finishing it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(controller: _controller),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.video.title)),
          body: Column(
            children: [
              player,
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Text(widget.video.description),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
