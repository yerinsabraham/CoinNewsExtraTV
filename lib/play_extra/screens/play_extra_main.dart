import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/play_extra_service.dart';
import '../services/global_battle_manager.dart';
import '../models/game_models.dart';
// Removed flutter_svg import (no longer used)
// Removed user_balance_service import (not used in this file)

class PlayExtraMain extends StatefulWidget {
  const PlayExtraMain({super.key});

  @override
  State<PlayExtraMain> createState() => _PlayExtraMainState();
}

class _PlayExtraMainState extends State<PlayExtraMain> with TickerProviderStateMixin {
  late PlayExtraService _playExtraService;
  late GlobalBattleManager _globalBattleManager;
  late TabController _tabController;
  late AnimationController _wheelAnimationController;
  late Animation<double> _wheelRotation;
  Timer? _battleTimer;
  bool _isSpinning = false;
  double _finalWheelAngle = 0.0; // For accurate winner selection
  
  // Forfeit system state
  bool _userHasJoinedCurrentBattle = false;
  int _userStakeAmount = 0;
  
  @override
  void initState() {
    super.initState();
    _playExtraService = PlayExtraService();
    _globalBattleManager = GlobalBattleManager();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize wheel animation controller
    _wheelAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Create spinning animation with accurate ending position
    _wheelRotation = Tween<double>(
      begin: 0,
      end: 1.0, // Will be calculated based on winner
    ).animate(CurvedAnimation(
      parent: _wheelAnimationController,
      curve: Curves.decelerate,
    ));
    
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _playExtraService.initialize();
    await _globalBattleManager.initialize();
    if (mounted) setState(() {});
  }

  void _startBattleTimer() {
    _battleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _playExtraService.isInBattle) {
        final battle = _playExtraService.currentBattle!;
        
        // Transition to battle-ready phase when countdown reaches zero
        if (battle.status == BattleSessionStatus.waiting && 
            battle.players.length >= 2 && 
            battle.timeRemaining.inSeconds <= 0) {
          // Change phase - show wheel, hide countdown
          print('🎯 Countdown finished! Battle phase starting...');
        }
        
        // Update UI every second
        setState(() {});
      }
    });
  }

  void _autoStartBattle() async {
    try {
      // Don't auto-start immediately - let user see the transition
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted && _playExtraService.isInBattle) {
        final battle = _playExtraService.currentBattle!;
        
        // Only transition to battle-ready phase, don't auto-spin
        if (battle.status == BattleSessionStatus.waiting) {
          setState(() {}); // Refresh UI to show battle-ready phase
          print('🎮 Battle ready! Players can now spin the wheel.');
        }
      }
    } catch (e) {
      print('Auto-start battle error: $e');
    }
  }

  @override
  void dispose() {
    _battleTimer?.cancel();
    _tabController.dispose();
    _wheelAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: ChangeNotifierProvider.value(
        value: _playExtraService,
        child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _handleExitAttempt,
          ),
          title: Row(
            children: [
              Image.asset(
                'assets/avatars/bullface.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.pets,
                  color: Color(0xFF00B359),
                  size: 32,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Play Extra',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            Consumer<PlayExtraService>(
              builder: (context, service, child) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00B359), Color(0xFF007A3D)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${service.playerCoins}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF00B359),
            labelColor: const Color(0xFF00B359),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.pets), text: 'Battle'),
              Tab(icon: Icon(Icons.analytics), text: 'Stats'),
              Tab(icon: Icon(Icons.history), text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBattleTab(),
            _buildStatsTab(),
            _buildHistoryTab(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildBattleTab() {
    return Consumer<PlayExtraService>(
      builder: (context, service, child) {
        // Check if player is in global battle
        final isInGlobalBattle = _globalBattleManager.isPlayerInBattle('current_user');
        
        if (isInGlobalBattle) {
          return _buildGlobalBattleView();
        } else {
          return _buildArenaSelection(service);
        }
      },
    );
  }

  // Global Battle Status Widget (Rocky Rabbit Style)
  Widget _buildGlobalBattleStatus() {
    return AnimatedBuilder(
      animation: _globalBattleManager,
      builder: (context, child) {
        final round = _globalBattleManager.currentRound;
        if (round == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.grey),
                SizedBox(width: 12),
                Text(
                  'No active battle',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _globalBattleManager.getBattleStatusColor(),
                _globalBattleManager.getBattleStatusColor().withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _globalBattleManager.getBattleStatusColor().withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _globalBattleManager.getBattleStatusText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (round.status == GlobalBattleStatus.accepting) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${round.players.length}/10 players joined',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (round.status == GlobalBattleStatus.accepting) ...[
                    Column(
                      children: [
                        Text(
                          round.formattedTimeRemaining,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Text(
                          'Join Time',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              
              // Battle Progress Bar
              if (round.status == GlobalBattleStatus.accepting) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: 1.0 - (round.timeRemaining.inSeconds / (2 * 60)),
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildArenaSelection(PlayExtraService service) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Global Battle Status - Always Visible at Top
          _buildGlobalBattleStatus(),
          const SizedBox(height: 20),
          
          // Bull Selection
          _buildBullSelection(service),
          const SizedBox(height: 24),
          
          // Arena Selection (only if can join)
          if (_globalBattleManager.canJoinBattle) ...[
            const Text(
              'Choose Your Arena & Join Battle',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...service.availableArenas.map((arena) => _buildArenaCard(arena, service)),
          ] else ...[
            // Show why can't join
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red),
              ),
              child: Column(
                children: [
                  const Icon(Icons.block, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    _globalBattleManager.isBattleInProgress 
                      ? 'Battle in Progress'
                      : 'Battle Round Full',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _globalBattleManager.isBattleInProgress
                      ? 'Wait for the current battle to finish'
                      : 'Maximum 10 players reached',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBullSelection(PlayExtraService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Your Bull Fighter',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: PlayExtraConfig.bullTypes.length,
              itemBuilder: (context, index) {
                final bullType = PlayExtraConfig.bullTypes[index];
                final isSelected = service.selectedBullType == bullType;
                
                return GestureDetector(
                  onTap: () => service.selectBull(bullType),
                  child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 92,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00B359) : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected ? const Color(0xFF00B359).withOpacity(0.2) : Colors.transparent,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: PlayExtraConfig.bullColors[bullType],
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/avatars/bullface.png',
                                width: 36,
                                height: 36,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            PlayExtraConfig.bullNames[bullType]!.split(' ')[0],
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF00B359) : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArenaCard(BattleArena arena, PlayExtraService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            arena.themeColor.withOpacity(0.3),
            arena.themeColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: arena.themeColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: arena.themeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(arena.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      arena.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      arena.description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showStakeDialog(arena, service),
              style: ElevatedButton.styleFrom(
                backgroundColor: arena.themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Enter Battle (${arena.minStake}-${arena.maxStake} CNE)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStakeDialog(BattleArena arena, PlayExtraService service) {
    final stakeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          'Enter ${arena.name}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stakeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Stake Amount (${arena.minStake}-${arena.maxStake} CNE)',
                labelStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your Balance: ${service.playerCoins} CNE',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final stake = int.tryParse(stakeController.text);
              if (stake != null && arena.isValidStake(stake)) {
                Navigator.pop(context);
                await _joinBattle(arena, stake, service);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: arena.themeColor),
            child: const Text(
              'Join Battle',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinBattle(BattleArena arena, int stake, PlayExtraService service) async {
    final globalBattleManager = GlobalBattleManager();
    
    // Create player and join global battle
    final player = BattlePlayer(
      id: 'current_user',
      username: 'Player',
      bullType: 'red', // Default to red, can be modified based on arena
      stakeAmount: stake,
      arenaId: arena.id,
      joinedAt: DateTime.now(),
    );
    
    final success = await globalBattleManager.joinBattle(player);
    
    if (success) {
      HapticFeedback.mediumImpact();
      
      // Track user participation for forfeit system
      setState(() {
        _userHasJoinedCurrentBattle = true;
        _userStakeAmount = stake;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Successfully joined global battle! (${stake} CNE)',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF00B359),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Force refresh the UI
      setState(() {});
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ Failed to join battle. Try again.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildActiveBattle(PlayExtraService service) {
    final battle = service.currentBattle!;
    final timeRemaining = battle.timeRemaining;
    final isWaitingPhase = battle.status == BattleSessionStatus.waiting;
    final hasSufficientPlayers = battle.players.length >= 2;
    final battleReadyToStart = hasSufficientPlayers && timeRemaining.inSeconds <= 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // PHASE 1: WAITING FOR PLAYERS (Show countdown, no wheel)
          if (isWaitingPhase && !battleReadyToStart) ...[
            // Waiting Phase Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFE55100)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.hourglass_empty, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    hasSufficientPlayers ? 'Battle Starting Soon!' : 'Waiting for More Players...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time Remaining: ${battle.formattedTimeRemaining}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasSufficientPlayers 
                      ? 'Get ready to spin the wheel!'
                      : 'Need ${2 - battle.players.length} more player(s)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Player List During Waiting
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Players Joined (${battle.players.length}/4)',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...battle.players.map((player) => _buildPlayerCard(player)),
                  if (battle.players.length < 4) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_circle_outline, color: Colors.grey, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'Waiting for more players...',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          // PHASE 2: BATTLE READY (Show wheel prominently, hide countdown)
          if (battleReadyToStart || battle.status == BattleSessionStatus.active) ...[
            // Battle Phase Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B359), Color(0xFF007A3D)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _isSpinning ? '🎰 Spinning the Wheel...' : '⚔️ Battle Ready!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // SPINNING WHEEL - TOP PRIORITY POSITION
            Center(
              child: Column(
                children: [
                  const Text(
                    'Rocky Rabbit Style Battle Wheel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAccurateSpinningWheel(battle.players),
                  const SizedBox(height: 20),
                  
                  // Spin Button
                  ElevatedButton(
                    onPressed: _isSpinning ? null : () => _startBattle(service),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSpinning ? Colors.grey : const Color(0xFF00B359),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isSpinning ? Icons.sync : Icons.casino,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isSpinning ? 'Spinning...' : 'Spin the Wheel!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Player List (Secondary during battle)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, color: Color(0xFF00B359), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Battle Participants (${battle.players.length})',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...battle.players.map((player) => _buildPlayerCard(player)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B359).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFF00B359), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Total Prize Pool: ${battle.totalStakePool} CNE',
                          style: const TextStyle(
                            color: Color(0xFF00B359),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Leave Battle Button (always available)
          TextButton.icon(
            onPressed: _isSpinning ? null : () => service.leaveBattle(),
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            label: Text(
              _isSpinning ? 'Cannot leave during spin' : 'Leave Battle',
              style: TextStyle(
                color: _isSpinning ? Colors.grey : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccurateSpinningWheel(List<BattlePlayer> players, {BattlePlayer? winner}) {
    return AnimatedBuilder(
      animation: _wheelRotation,
      builder: (context, child) {
        final currentRotation = _finalWheelAngle * _wheelRotation.value;
        
        return Container(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring with glow effect
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00B359).withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              
              // Accurate spinning wheel
              Container(
                width: 230,
                height: 230,
                child: CustomPaint(
                  painter: AccurateBattleWheelPainter(
                    players, 
                    rotation: currentRotation,
                    winner: winner,
                  ),
                  size: const Size(230, 230),
                ),
              ),
              
              // Center hub
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF00B359), width: 4),
                ),
                child: const Icon(
                  Icons.casino,
                  color: Color(0xFF00B359),
                  size: 35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Global Battle View - Rocky Rabbit Style
  Widget _buildGlobalBattleView() {
    return AnimatedBuilder(
      animation: _globalBattleManager,
      builder: (context, child) {
        final round = _globalBattleManager.currentRound;
        if (round == null) return const SizedBox.shrink();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Battle Status Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _globalBattleManager.getBattleStatusColor(),
                      _globalBattleManager.getBattleStatusColor().withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      _globalBattleManager.getBattleStatusText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (round.status == GlobalBattleStatus.accepting) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Join closes in: ${round.formattedTimeRemaining}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Spinning Wheel (main attraction when battling)
              if (round.status == GlobalBattleStatus.battling || round.status == GlobalBattleStatus.finished) ...[
                const Text(
                  'Rocky Rabbit Battle Wheel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAccurateSpinningWheel(round.players, winner: round.winner),
                const SizedBox(height: 20),
                
                if (round.status == GlobalBattleStatus.battling && !_isSpinning) ...[
                  ElevatedButton(
                    onPressed: () => _spinWheelAccurately(round.players),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B359),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.casino, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Spin the Wheel!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ] else if (_isSpinning) ...[
                  const ElevatedButton(
                    onPressed: null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Spinning...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
              ],
              
              // Player List
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: _globalBattleManager.getBattleStatusColor(),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Battle Participants (${round.players.length}/10)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...round.players.map((player) => _buildGlobalPlayerCard(player, isWinner: player.id == round.winner?.id)),
                    
                    // Show total prize pool
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B359).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Color(0xFF00B359), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Total Prize Pool: ${round.players.fold(0, (sum, player) => sum + player.stakeAmount)} CNE',
                            style: const TextStyle(
                              color: Color(0xFF00B359),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Leave Battle (only during accepting phase)
              if (round.status == GlobalBattleStatus.accepting) ...[
                TextButton.icon(
                  onPressed: () {
                    _globalBattleManager.leaveBattle('current_user');
                  },
                  icon: const Icon(Icons.exit_to_app, color: Colors.red),
                  label: const Text(
                    'Leave Battle',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerCard(BattlePlayer player) {
    final isCurrentPlayer = player.id == 'current_user';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentPlayer ? const Color(0xFF00B359).withOpacity(0.2) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentPlayer ? const Color(0xFF00B359) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: PlayExtraConfig.bullColors[player.bullType] ?? Colors.blue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Image.asset(
                'assets/avatars/bullface.png',
                width: 16,
                height: 16,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, color: Colors.white, size: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentPlayer ? '${player.username} (You)' : player.username,
                  style: TextStyle(
                    color: isCurrentPlayer ? const Color(0xFF00B359) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  PlayExtraConfig.bullNames[player.bullType] ?? 'Unknown Bull',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${player.stakeAmount} CNE',
            style: const TextStyle(
              color: Color(0xFF00B359),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalPlayerCard(BattlePlayer player, {bool isWinner = false}) {
    final isCurrentPlayer = player.id == 'current_user';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinner 
          ? Colors.amber.withOpacity(0.3)
          : (isCurrentPlayer ? const Color(0xFF00B359).withOpacity(0.2) : const Color(0xFF1A1A1A)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWinner 
            ? Colors.amber
            : (isCurrentPlayer ? const Color(0xFF00B359) : Colors.transparent),
          width: isWinner ? 3 : 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isWinner 
                ? Colors.amber
                : (PlayExtraConfig.bullColors[player.bullType] ?? Colors.blue),
              borderRadius: BorderRadius.circular(18),
            ),
            child: isWinner
                ? const Icon(Icons.emoji_events, color: Colors.white, size: 20)
                : Image.asset(
                    'assets/avatars/bullface.png',
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, color: Colors.white, size: 18),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isCurrentPlayer ? '${player.username} (You)' : player.username,
                      style: TextStyle(
                        color: isWinner 
                          ? Colors.amber
                          : (isCurrentPlayer ? const Color(0xFF00B359) : Colors.white),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (isWinner) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                      const Text(' WINNER', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
                Text(
                  PlayExtraConfig.bullNames[player.bullType] ?? 'Unknown Bull',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${player.stakeAmount} CNE',
            style: TextStyle(
              color: isWinner ? Colors.amber : const Color(0xFF00B359),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Accurate wheel spinning with predetermined winner
  Future<void> _spinWheelAccurately(List<BattlePlayer> players) async {
    if (_isSpinning || players.isEmpty) return;
    
    setState(() => _isSpinning = true);
    
    // Calculate the winner angle BEFORE spinning starts
    final segmentAngle = 2 * math.pi / players.length;
    final random = math.Random();
    
    // Randomly select winner index
    final winnerIndex = random.nextInt(players.length);
    final winner = players[winnerIndex];
    
    // Calculate the final angle needed to point arrow to winner
    // Arrow points up (north), so we calculate the angle to point to winner's segment center
    final targetSegmentCenter = winnerIndex * segmentAngle + (segmentAngle / 2);
    final baseSpins = 4 + random.nextDouble() * 2; // 4-6 full rotations
    _finalWheelAngle = (baseSpins * 2 * math.pi) - targetSegmentCenter;
    
    // Update the animation to use the calculated final angle
    _wheelRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _wheelAnimationController, curve: Curves.decelerate)
    );
    
    // Start spinning animation
    _wheelAnimationController.reset();
    _wheelAnimationController.forward();
    
    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 3));
    
    // Verify winner using the accurate calculation
    final calculatedWinner = AccurateBattleWheelPainter.calculateWinner(players, _finalWheelAngle);
    
    print('🎯 Intended winner: ${winner.username}');
    print('🎯 Calculated winner: ${calculatedWinner?.username ?? "None"}');
    
    setState(() => _isSpinning = false);
    
    // Show result
    if (mounted) {
      _showAccurateWheelResult(calculatedWinner ?? winner);
    }
  }

  void _showAccurateWheelResult(BattlePlayer winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            const SizedBox(width: 8),
            Text(
              '${winner.username} Wins!',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉 Congratulations to ${winner.username}!',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Bull: ${PlayExtraConfig.bullNames[winner.bullType]}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Stake: ${winner.stakeAmount} CNE',
              style: const TextStyle(color: Color(0xFF00B359), fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Battle is now finished, reset forfeit tracking
              setState(() {
                _userHasJoinedCurrentBattle = false;
                _userStakeAmount = 0;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B359)),
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startBattle(PlayExtraService service) async {
    try {
      setState(() => _isSpinning = true);
      
      // Start wheel spinning animation
      _wheelAnimationController.reset();
      _wheelAnimationController.forward();
      
      // Wait for animation to complete
      await Future.delayed(const Duration(seconds: 3));
      
      // Get battle result
      final result = await service.startBattle();
      
      setState(() => _isSpinning = false);
      
      if (mounted) {
        _showBattleResult(result);
      }
    } catch (e) {
      setState(() => _isSpinning = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Battle error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showBattleResult(BattleResult result) {
    final isWinner = result.winnerId == 'current_user';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Row(
          children: [
            Icon(
              isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              color: isWinner ? Colors.amber : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 8),
            Text(
              isWinner ? 'Victory!' : 'Defeat!',
              style: TextStyle(
                color: isWinner ? Colors.amber : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          isWinner 
            ? 'Congratulations! You won ${result.winnerReward} CNE!'
            : 'Better luck next time!',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B359)),
            child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return Consumer<PlayExtraService>(
      builder: (context, service, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatsCard('Wins', '${service.playerStats.totalWins}', Icons.emoji_events),
              _buildStatsCard('Battles', '${service.playerStats.totalBattles}', Icons.sports_martial_arts),
              _buildStatsCard('Win Rate', '${(service.playerStats.winRate * 100).toStringAsFixed(1)}%', Icons.trending_up),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00B359),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF00B359), fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<PlayExtraService>(
      builder: (context, service, child) {
        final history = service.getFormattedBattleHistory();
        
        if (history.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, color: Colors.grey, size: 64),
                SizedBox(height: 16),
                Text('No battle history yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final battle = history[index];
            final isWin = battle.startsWith('WON');
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isWin ? Colors.green : Colors.red, width: 1),
              ),
              child: Row(
                children: [
                  Icon(isWin ? Icons.emoji_events : Icons.close, color: isWin ? Colors.green : Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(battle, style: const TextStyle(color: Colors.white, fontSize: 12))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Forfeit System Methods
  Future<bool> _handleBackPress() async {
    return await _handleExitAttempt();
  }
  
  Future<bool> _handleExitAttempt() async {
    final globalBattleManager = GlobalBattleManager();
    
    // Check if user has joined current battle
    if (_userHasJoinedCurrentBattle) {
      final currentRound = globalBattleManager.currentRound;
      
      if (currentRound != null) {
        final isGameActive = currentRound.status == GlobalBattleStatus.battling || 
                           currentRound.status == GlobalBattleStatus.accepting;
        final isWheelSpinning = _isSpinning;
        final playerCount = currentRound.players.length;
        
        // Only show forfeit dialog if game is active AND there are 2+ players
        if ((isGameActive || isWheelSpinning) && playerCount >= 2) {
          return await _showForfeitDialog();
        } else if (isGameActive || isWheelSpinning) {
          // Single player game - allow normal exit without forfeit
          Navigator.pop(context);
          return true;
        } else {
          // Game finished, show safe exit dialog
          return await _showSafeExitDialog();
        }
      }
    }
    
    // No active battle, allow normal exit
    Navigator.pop(context);
    return true;
  }
  
  Future<bool> _showForfeitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 32),
            const SizedBox(width: 8),
            const Text(
              'Forfeit Game?',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ The battle is currently active!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'If you leave now, you will forfeit your stake and lose:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$_userStakeAmount CNE',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to forfeit and leave?',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Stay in Game',
              style: TextStyle(color: Color(0xFF00B359), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Forfeit & Leave',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    
    if (result == true) {
      // User chose to forfeit
      await _processForfeiture();
      Navigator.pop(context);
      return true;
    }
    
    return false; // Stay in game
  }
  
  Future<bool> _showSafeExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 8),
            const Text(
              'Exit Game',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✅ The battle has finished!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your participation is complete and your stake is safe.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Your amount is saved!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to exit Play Extra?',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Stay',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B359)),
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    
    if (result == true) {
      Navigator.pop(context);
      return true;
    }
    
    return false;
  }
  
  Future<void> _processForfeiture() async {
    // Here you would implement the actual forfeiture logic
    // For example: deduct the stake from user's balance, log the forfeit, etc.
    
    _userHasJoinedCurrentBattle = false;
    _userStakeAmount = 0;
    
    // Show forfeit confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '💸 You forfeited $_userStakeAmount CNE by leaving the active battle',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// Enhanced wheel painter with accurate winner calculation
class AccurateBattleWheelPainter extends CustomPainter {
  final List<BattlePlayer> players;
  final double rotation;
  final BattlePlayer? winner;
  
  AccurateBattleWheelPainter(this.players, {this.rotation = 0.0, this.winner});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    if (players.isEmpty) return;
    
    final segmentAngle = 2 * math.pi / players.length;
    
    for (int i = 0; i < players.length; i++) {
      final startAngle = (i * segmentAngle - math.pi / 2) + rotation;
      final player = players[i];
      
      // Highlight winner segment
      final isWinner = winner != null && player.id == winner!.id;
      
      // Get player color with winner highlight
      Color playerColor = PlayExtraConfig.bullColors[player.bullType] ?? 
          [Colors.blue, Colors.red, Colors.green, Colors.purple, Colors.orange, Colors.teal][i % 6];
      
      if (isWinner) {
        playerColor = Colors.amber; // Gold for winner
      }
      
      // Draw colorful segment
      final paint = Paint()
        ..color = playerColor
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );
      
      // Draw segment border (thicker for winner)
      final borderPaint = Paint()
        ..color = isWinner ? Colors.yellow : Colors.white
        ..strokeWidth = isWinner ? 5 : 3
        ..style = PaintingStyle.stroke;
      
      final x1 = center.dx + radius * math.cos(startAngle);
      final y1 = center.dy + radius * math.sin(startAngle);
      
      canvas.drawLine(center, Offset(x1, y1), borderPaint);
      
      // Draw player indicator
      final iconAngle = startAngle + segmentAngle / 2;
      final iconRadius = radius * 0.7;
      final iconX = center.dx + iconRadius * math.cos(iconAngle);
      final iconY = center.dy + iconRadius * math.sin(iconAngle);
      
      final iconPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(iconX, iconY), isWinner ? 12 : 10, iconPaint);
      
      // Inner accent (show bull icon or crown for winner)
      final accentPaint = Paint()
        ..color = isWinner ? Colors.amber : playerColor.withOpacity(0.8)
        ..style = PaintingStyle.fill;
        
      canvas.drawCircle(Offset(iconX, iconY), isWinner ? 8 : 6, accentPaint);
    }
    
    // Draw pointer at top (static red arrow)
    final pointerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    final pointerPath = Path();
    pointerPath.moveTo(center.dx, 10); // Top point
    pointerPath.lineTo(center.dx - 15, 40); // Bottom left
    pointerPath.lineTo(center.dx + 15, 40); // Bottom right
    pointerPath.close();
    
    canvas.drawPath(pointerPath, pointerPaint);
    
    // White border for pointer
    final pointerBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawPath(pointerPath, pointerBorderPaint);
  }
  
  // Calculate which player the arrow points to
  static BattlePlayer? calculateWinner(List<BattlePlayer> players, double finalRotation) {
    if (players.isEmpty) return null;
    
    final segmentAngle = 2 * math.pi / players.length;
    
    // Normalize rotation (arrow points up/north)
    double normalizedRotation = (finalRotation % (2 * math.pi));
    if (normalizedRotation < 0) normalizedRotation += 2 * math.pi;
    
    // Calculate which segment the arrow points to
    // Arrow points up (north), so we need to find the segment at the top
    double arrowAngle = (2 * math.pi - normalizedRotation) % (2 * math.pi);
    int segmentIndex = ((arrowAngle + (segmentAngle / 2)) ~/ segmentAngle) % players.length;
    
    return players[segmentIndex];
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}