import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../services/live_video_config.dart';
import '../widgets/ads_carousel.dart';
import '../services/user_balance_service.dart';

class LiveTvPage extends StatefulWidget {
  const LiveTvPage({super.key});

  @override
  State<LiveTvPage> createState() => _LiveTvPageState();
}

class _LiveTvPageState extends State<LiveTvPage> with TickerProviderStateMixin {
  late YoutubePlayerController _controller;
  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Watch time tracking
  Timer? _watchTimer;
  int _watchTimeSeconds = 0;
  bool _isClaimingReward = false;

  // Simple UI state
  int viewerCount = 1234;
  bool isLiked = false;
  int likeCount = 120;

  // Poll state
  String? selectedPollOption;
  Map<String, int> pollResults = {
    'Yes': 245,
    'No': 89,
    'Maybe': 156,
  };

  // No local hard-coded comments; comments are loaded from Firestore

  @override
  void initState() {
    super.initState();

    _controller = YoutubePlayerController(
      initialVideoId: LiveVideoConfig.getVideoId(),
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        isLive: true,
        disableDragSeek: true,
        mute: false,
        useHybridComposition: true,
        enableCaption: true,
        forceHD: false,
      ),
    );

    _tabController = TabController(length: 2, vsync: this);

    // Add comprehensive error handling and autoplay retry mechanism
    _controller.addListener(() {
      if (_controller.value.hasError) {
        debugPrint('❌ Live Stream Error: ${_controller.value.errorCode}');
        // Try to reload the video on error
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _controller.load(LiveVideoConfig.getVideoId());
          }
        });
      } else if (_controller.value.isReady && !_controller.value.isPlaying) {
        debugPrint('✅ Live stream ready, attempting autoplay...');
        // Multiple retry attempts for autoplay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_controller.value.isPlaying) {
            try {
              _controller.play();
            } catch (e) {
              debugPrint('Error playing video: $e');
            }
          }
        });
        // Additional retry after 1 second
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted && !_controller.value.isPlaying) {
            try {
              _controller.play();
            } catch (e) {
              debugPrint('Error playing video (retry): $e');
            }
          }
        });
      }
    });

    // start a periodic timer to track watch time; auto-claim when threshold met
    _watchTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_controller.value.isPlaying) {
        setState(() {
          _watchTimeSeconds++;
        });

        if (LiveVideoConfig.hasMetWatchRequirement(_watchTimeSeconds) &&
            !_isClaimingReward) {
          _claimWatchReward();
        }
      }
    });
  }

  @override
  void dispose() {
    _watchTimer?.cancel();
    _controller.dispose();
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _claimWatchReward() async {
    if (_isClaimingReward) return;
    setState(() => _isClaimingReward = true);

    try {
      final balanceService =
          Provider.of<UserBalanceService>(context, listen: false);
      await balanceService.addBalance(
          LiveVideoConfig.watchReward, 'Live TV Watch Reward');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Earned ${LiveVideoConfig.watchReward} CNE for watching live TV!'),
            backgroundColor: const Color(0xFF006833),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Reset watch timer so user can earn again after another period
      setState(() {
        _watchTimeSeconds = 0;
        _isClaimingReward = false;
      });
    } catch (e) {
      setState(() => _isClaimingReward = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error claiming reward: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please sign in to comment'),
          backgroundColor: Colors.red));
      return;
    }

    final username = user.displayName ?? 'User${user.uid.substring(0, 6)}';

    final payload = {
      'videoId': LiveVideoConfig.getVideoId(),
      'userId': user.uid,
      'username': username,
      'message': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Optimistic UI: clear input immediately
    _chatController.clear();

    _firestore.collection('live_comments').add(payload).then((_) async {
      // Optionally reward small participation
      try {
        final balanceService =
            Provider.of<UserBalanceService>(context, listen: false);
        await balanceService.addBalance(0.05, 'Live comment');
      } catch (_) {}
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to post comment'),
          backgroundColor: Colors.red));
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    // older than a week -> show date
    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }

  Widget _buildChatTab() {
    final videoId = LiveVideoConfig.getVideoId();

    final stream = _firestore
        .collection('live_comments')
        .where('videoId', isEqualTo: videoId)
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots();

    return Container(
      color: Colors.grey[900],
      child: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error loading comments',
                            style: TextStyle(color: Colors.white70)));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF006833))));
                  }

                  final docs = snapshot.data?.docs ?? [];

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final username = data['username'] ?? 'Anon';
                      final message = data['message'] ?? '';
                      final timestamp =
                          (data['timestamp'] as Timestamp?)?.toDate() ??
                              DateTime.now();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF006833),
                                child: Text(username[0].toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12))),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text(username,
                                          style: const TextStyle(
                                              color: Color(0xFF006833),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                      const SizedBox(width: 8),
                                      Text(_formatTimestamp(timestamp),
                                          style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                              fontSize: 10))
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(message,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 14)),
                                  ]),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // NOTE: chat input moved to a full-screen modal to avoid bottom-overflow and
            // to provide a focused chat/poll experience. Tap the "Open Chat" bar on the
            // Live TV page to open the modal.
          ],
        ),
      ),
    );
  }

  void _openChatModal({int initialIndex = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Use StatefulBuilder to manage state within the modal
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.92,
              minChildSize: 0.4,
              maxChildSize: 0.98,
              expand: false,
              builder: (context, scrollController) {
                return Material(
                  color: Colors.grey[900],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: DefaultTabController(
                    initialIndex: initialIndex,
                    length: 2,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(children: [
                            const Expanded(
                                child: Text('Live Chat & Poll',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold))),
                            IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () => Navigator.of(context).pop()),
                          ]),
                        ),
                        const TabBar(
                            tabs: [Tab(text: 'Chat'), Tab(text: 'Poll')],
                            indicatorColor: Color(0xFF006833),
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white70),
                        Expanded(
                          child: TabBarView(children: [
                            // Chat modal tab
                            Column(
                              children: [
                                Expanded(
                                  child: StreamBuilder<QuerySnapshot>(
                                    stream: _firestore
                                        .collection('live_comments')
                                        .where('videoId',
                                            isEqualTo:
                                                LiveVideoConfig.getVideoId())
                                        .orderBy('timestamp', descending: true)
                                        .limit(200)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return const Center(
                                            child: Text(
                                                'Error loading comments',
                                                style: TextStyle(
                                                    color: Colors.white70)));
                                      }
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                            child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        Color(0xFF006833))));
                                      }

                                      final docs = snapshot.data?.docs ?? [];

                                      return ListView.builder(
                                        controller: scrollController,
                                        reverse: true,
                                        padding: const EdgeInsets.all(16),
                                        itemCount: docs.length,
                                        itemBuilder: (context, index) {
                                          final doc = docs[index];
                                          final data = doc.data()
                                              as Map<String, dynamic>;
                                          final username =
                                              data['username'] ?? 'Anon';
                                          final message = data['message'] ?? '';
                                          final timestamp =
                                              (data['timestamp'] as Timestamp?)
                                                      ?.toDate() ??
                                                  DateTime.now();

                                          return Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 12),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor:
                                                        const Color(0xFF006833),
                                                    child: Text(
                                                        username[0]
                                                            .toUpperCase(),
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12))),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(children: [
                                                          Text(username,
                                                              style: const TextStyle(
                                                                  color: Color(
                                                                      0xFF006833),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      12)),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                              _formatTimestamp(
                                                                  timestamp),
                                                              style:
                                                                  TextStyle(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.5),
                                                                      fontSize:
                                                                          10))
                                                        ]),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(message,
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        14)),
                                                      ]),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),

                                // Input (keyboard-safe) inside modal
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      bottom: MediaQuery.of(context)
                                              .viewInsets
                                              .bottom +
                                          8,
                                      top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                            color: Colors.white
                                                .withOpacity(0.06))),
                                    child: Row(children: [
                                      Expanded(
                                          child: TextField(
                                              controller: _chatController,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                              onSubmitted: (_) =>
                                                  _sendChatMessage(),
                                              decoration: InputDecoration(
                                                  hintText: 'Type a message...',
                                                  hintStyle: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.5)),
                                                  border: InputBorder.none))),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                          onTap: _sendChatMessage,
                                          child: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: const BoxDecoration(
                                                  color: Color(0xFF006833),
                                                  shape: BoxShape.circle),
                                              child: const Icon(Icons.send,
                                                  color: Colors.white,
                                                  size: 20))),
                                    ]),
                                  ),
                                ),
                              ],
                            ),

                            // Poll modal tab - build poll with modal state setter
                            SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              child: _buildPollTabForModal(setModalState),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPollTab() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Container(
          color: Colors.grey[900],
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Live Poll',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato')),
              const SizedBox(height: 8),
              // Fiat symbol removed from poll question — keep numeric reference only
              const Text('Will Bitcoin reach 100K this month?',
                  style: TextStyle(
                      color: Colors.white, fontSize: 16, fontFamily: 'Lato')),
              const SizedBox(height: 20),
              ...pollResults.entries.map((entry) {
                final option = entry.key;
                final votes = entry.value;
                final totalVotes = pollResults.values.reduce((a, b) => a + b);
                final percentage = (votes / totalVotes * 100).round();
                final isSelected = selectedPollOption == option;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      // Update both the widget state and modal state for immediate feedback
                      setState(() {
                        if (selectedPollOption != option) {
                          selectedPollOption = option;
                          pollResults[option] = votes + 1;
                        }
                      });
                      setModalState(() {
                        if (selectedPollOption != option) {
                          selectedPollOption = option;
                          pollResults[option] = votes + 1;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF006833).withOpacity(0.3)
                            : Colors.black,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isSelected
                                ? const Color(0xFF006833)
                                : Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(option,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'Lato'))),
                          Text('$percentage% ($votes)',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14)),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle,
                                color: Color(0xFF006833), size: 20)
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Poll builder method for modal that uses the modal's StateSetter
  Widget _buildPollTabForModal(StateSetter setModalState) {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Poll',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato')),
          const SizedBox(height: 8),
          const Text('Will Bitcoin reach 100K this month?',
              style: TextStyle(
                  color: Colors.white, fontSize: 16, fontFamily: 'Lato')),
          const SizedBox(height: 20),
          ...pollResults.entries.map((entry) {
            final option = entry.key;
            final votes = entry.value;
            final totalVotes = pollResults.values.reduce((a, b) => a + b);
            final percentage = (votes / totalVotes * 100).round();
            final isSelected = selectedPollOption == option;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  if (selectedPollOption != option) {
                    // Update both states
                    setState(() {
                      selectedPollOption = option;
                      pollResults[option] = votes + 1;
                    });
                    setModalState(() {
                      selectedPollOption = option;
                      pollResults[option] = votes + 1;
                    });
                    // Show feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('You voted for: $option'),
                        backgroundColor: const Color(0xFF006833),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF006833).withOpacity(0.3)
                        : Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isSelected
                            ? const Color(0xFF006833)
                            : Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(option,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Lato'))),
                      Text('$percentage% ($votes)',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14)),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle,
                            color: Color(0xFF006833), size: 20)
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Live TV',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato')),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.red, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              const Text('LIVE',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
      body: Column(children: [
        YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: const Color(0xFF006833),
          progressColors: const ProgressBarColors(
              playedColor: Color(0xFF006833), handleColor: Color(0xFF006833)),
        ),

        // Info, ad banner and actions
        Container(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(LiveVideoConfig.liveStreamTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato'))),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('$viewerCount viewers',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 8),
            Text(LiveVideoConfig.liveStreamDescription,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontFamily: 'Lato')),
            const SizedBox(height: 16),

            // Ads carousel with special offer slide (in-house promotion)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AdsCarousel(
                extraBanners: [
                  {
                    'image': 'assets/images/special_offer.png',
                    'title': 'Special Offer: 2x Rewards for Live Viewers!',
                    'url': LiveVideoConfig.promoBannerRoute.startsWith('http')
                        ? LiveVideoConfig.promoBannerRoute
                        : '',
                  }
                ],
              ),
            ),

            // Small open-chat bar to launch modal that covers the screen
            GestureDetector(
              onTap: () => _openChatModal(initialIndex: 0),
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.chat_bubble_outline,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                      child: Text('Open Chat',
                          style: TextStyle(color: Colors.white))),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_up, color: Colors.white)
                ]),
              ),
            ),

            Row(children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isLiked) {
                      likeCount--;
                      isLiked = false;
                    } else {
                      likeCount++;
                      isLiked = true;
                    }
                  });
                  // Show feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isLiked ? 'Liked!' : 'Like removed'),
                      backgroundColor: const Color(0xFF006833),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Row(children: [
                  Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: isLiked
                        ? const Color(0xFF006833)
                        : Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    likeCount.toString(),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 14),
                  ),
                ]),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () async {
                  try {
                    final shareUrl = LiveVideoConfig.primaryLiveStreamUrl;
                    await Share.share(
                      'Watch ${LiveVideoConfig.liveStreamTitle} live on CoinNewsExtra! $shareUrl',
                      subject: LiveVideoConfig.liveStreamTitle,
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error sharing stream'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Row(children: [
                  Icon(
                    Icons.share_outlined,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Share',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 14),
                  ),
                ]),
              ),
              const Spacer(),

              // Watch progress / manual claim
              if (LiveVideoConfig.hasMetWatchRequirement(_watchTimeSeconds))
                ElevatedButton(
                    onPressed: _isClaimingReward ? null : _claimWatchReward,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006833),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8)),
                    child: _isClaimingReward
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Claim ${LiveVideoConfig.watchReward} CNE',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)))
              else
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(
                        'Watch ${LiveVideoConfig.formatWatchTime(LiveVideoConfig.getRemainingWatchTime(_watchTimeSeconds))} more',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)))
            ])
          ]),
        ),

        // Tabs
        Container(
            color: Colors.grey[900],
            child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF006833),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                tabs: const [Tab(text: 'Chat'), Tab(text: 'Poll')])),

        Expanded(
            child: TabBarView(
                controller: _tabController,
                children: [_buildChatTab(), _buildPollTab()])),
      ]),
    );
  }
}

class LiveComment {
  final String username;
  final String message;
  final String timestamp;
  bool isLiked;

  LiveComment(
      {required this.username,
      required this.message,
      required this.timestamp,
      this.isLiked = false});
}
