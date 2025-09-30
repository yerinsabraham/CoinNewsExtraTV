/// Smart Contract Governance & Upgrade Strategy
/// Implements multisig governance, timelock, and upgrade mechanisms
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/environment_config.dart';
import 'smart_contract_service.dart';

class GovernanceService {
  static GovernanceService? _instance;
  static GovernanceService get instance => _instance ??= GovernanceService._();
  
  GovernanceService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SmartContractService _contractService = SmartContractService.instance;
  
  // Governance parameters
  static const int MIN_PROPOSAL_THRESHOLD = 1000000; // 1M CNE tokens
  static const Duration VOTING_PERIOD = Duration(days: 7);
  static const Duration TIMELOCK_DELAY = Duration(days: 2);
  static const double QUORUM_THRESHOLD = 0.4; // 40% participation
  static const double APPROVAL_THRESHOLD = 0.6; // 60% approval
  
  /// Initialize governance system
  Future<void> initialize() async {
    await _initializeGovernanceContracts();
    await _loadGovernanceState();
    await _scheduleGovernanceTasks();
    
    _logGovernance('✅ GovernanceService initialized with multisig and timelock');
  }
  
  /// Create upgrade proposal
  Future<String> createUpgradeProposal({
    required String title,
    required String description,
    required String contractToUpgrade,
    required String newImplementationAddress,
    required Map<String, dynamic> upgradeParameters,
    required String proposer,
  }) async {
    try {
      // Validate proposer has enough tokens
      final proposerBalance = await _contractService.getCNEBalance(proposer);
      if (proposerBalance < MIN_PROPOSAL_THRESHOLD) {
        throw GovernanceException('Insufficient CNE balance for proposal. Required: $MIN_PROPOSAL_THRESHOLD');
      }
      
      final proposalId = _generateProposalId();
      final proposal = GovernanceProposal(
        id: proposalId,
        title: title,
        description: description,
        proposer: proposer,
        contractToUpgrade: contractToUpgrade,
        newImplementationAddress: newImplementationAddress,
        upgradeParameters: upgradeParameters,
        createdAt: DateTime.now(),
        votingStartsAt: DateTime.now().add(const Duration(hours: 24)), // 24h delay
        votingEndsAt: DateTime.now().add(const Duration(hours: 24)).add(VOTING_PERIOD),
        status: ProposalStatus.pending,
        votesFor: 0,
        votesAgainst: 0,
        totalVotes: 0,
      );
      
      // Store proposal
      await _firestore.collection('governance_proposals').doc(proposalId).set(proposal.toMap());
      
      // Lock proposer's tokens during voting period
      await _lockProposerTokens(proposer, MIN_PROPOSAL_THRESHOLD, proposal.votingEndsAt);
      
      _logGovernance('📋 Upgrade proposal created: $proposalId - $title');
      
      return proposalId;
      
    } catch (e) {
      _logGovernanceError('Failed to create upgrade proposal: $e');
      rethrow;
    }
  }
  
  /// Vote on proposal
  Future<void> voteOnProposal({
    required String proposalId,
    required String voter,
    required bool support,
    required String reason,
  }) async {
    try {
      final proposalDoc = await _firestore.collection('governance_proposals').doc(proposalId).get();
      
      if (!proposalDoc.exists) {
        throw GovernanceException('Proposal not found: $proposalId');
      }
      
      final proposal = GovernanceProposal.fromMap(proposalDoc.data()!);
      
      // Validate voting period
      final now = DateTime.now();
      if (now.isBefore(proposal.votingStartsAt)) {
        throw GovernanceException('Voting has not started yet');
      }
      if (now.isAfter(proposal.votingEndsAt)) {
        throw GovernanceException('Voting period has ended');
      }
      
      // Check if user already voted
      final existingVote = await _firestore
          .collection('governance_votes')
          .where('proposalId', isEqualTo: proposalId)
          .where('voter', isEqualTo: voter)
          .get();
      
      if (existingVote.docs.isNotEmpty) {
        throw GovernanceException('User has already voted on this proposal');
      }
      
      // Get voter's CNE balance at proposal creation (snapshot)
      final voterBalance = await _getVoterBalanceAtSnapshot(voter, proposal.createdAt);
      if (voterBalance <= 0) {
        throw GovernanceException('No CNE balance to vote');
      }
      
      // Record vote
      await _firestore.collection('governance_votes').add({
        'proposalId': proposalId,
        'voter': voter,
        'support': support,
        'reason': reason,
        'votingPower': voterBalance,
        'timestamp': FieldValue.serverTimestamp(),
        'environment': EnvironmentConfig.currentEnvironment.name,
      });
      
      // Update proposal vote counts
      final batch = _firestore.batch();
      final proposalRef = _firestore.collection('governance_proposals').doc(proposalId);
      
      if (support) {
        batch.update(proposalRef, {
          'votesFor': FieldValue.increment(voterBalance.toInt()),
          'totalVotes': FieldValue.increment(voterBalance.toInt()),
        });
      } else {
        batch.update(proposalRef, {
          'votesAgainst': FieldValue.increment(voterBalance.toInt()),
          'totalVotes': FieldValue.increment(voterBalance.toInt()),
        });
      }
      
      await batch.commit();
      
      _logGovernance('🗳️ Vote recorded: $voter ${support ? 'supports' : 'opposes'} proposal $proposalId');
      
    } catch (e) {
      _logGovernanceError('Failed to vote on proposal $proposalId: $e');
      rethrow;
    }
  }
  
  /// Execute approved proposal
  Future<void> executeProposal(String proposalId) async {
    try {
      final proposalDoc = await _firestore.collection('governance_proposals').doc(proposalId).get();
      
      if (!proposalDoc.exists) {
        throw GovernanceException('Proposal not found: $proposalId');
      }
      
      final proposal = GovernanceProposal.fromMap(proposalDoc.data()!);
      
      // Validate proposal can be executed
      await _validateProposalForExecution(proposal);
      
      // Check timelock delay
      if (DateTime.now().isBefore(proposal.votingEndsAt.add(TIMELOCK_DELAY))) {
        throw GovernanceException('Timelock delay not met. Can execute after ${proposal.votingEndsAt.add(TIMELOCK_DELAY)}');
      }
      
      // Execute the upgrade
      final executionResult = await _executeContractUpgrade(proposal);
      
      // Update proposal status
      await _firestore.collection('governance_proposals').doc(proposalId).update({
        'status': ProposalStatus.executed.name,
        'executedAt': FieldValue.serverTimestamp(),
        'executionResult': executionResult,
      });
      
      // Unlock proposer tokens
      await _unlockProposerTokens(proposal.proposer, MIN_PROPOSAL_THRESHOLD);
      
      _logGovernance('✅ Proposal executed: $proposalId - ${proposal.title}');
      
    } catch (e) {
      _logGovernanceError('Failed to execute proposal $proposalId: $e');
      
      // Mark as failed
      await _firestore.collection('governance_proposals').doc(proposalId).update({
        'status': ProposalStatus.failed.name,
        'failureReason': e.toString(),
        'failedAt': FieldValue.serverTimestamp(),
      });
      
      rethrow;
    }
  }
  
  /// Emergency pause mechanism
  Future<void> emergencyPause({
    required String contractAddress,
    required String reason,
    required List<String> multisigSigners,
  }) async {
    try {
      // Validate multisig signatures
      if (multisigSigners.length < 3) {
        throw GovernanceException('Emergency pause requires at least 3 multisig signatures');
      }
      
      // Record emergency action
      await _firestore.collection('emergency_actions').add({
        'type': 'pause',
        'contractAddress': contractAddress,
        'reason': reason,
        'signers': multisigSigners,
        'timestamp': FieldValue.serverTimestamp(),
        'environment': EnvironmentConfig.currentEnvironment.name,
      });
      
      // Execute pause through contract
      await _contractService.pauseContract(contractAddress);
      
      _logGovernance('🚨 Emergency pause executed for $contractAddress: $reason');
      
    } catch (e) {
      _logGovernanceError('Failed to execute emergency pause: $e');
      rethrow;
    }
  }
  
  /// Emergency unpause mechanism
  Future<void> emergencyUnpause({
    required String contractAddress,
    required String reason,
    required List<String> multisigSigners,
  }) async {
    try {
      // Validate multisig signatures
      if (multisigSigners.length < 5) {
        throw GovernanceException('Emergency unpause requires at least 5 multisig signatures');
      }
      
      // Record emergency action
      await _firestore.collection('emergency_actions').add({
        'type': 'unpause',
        'contractAddress': contractAddress,
        'reason': reason,
        'signers': multisigSigners,
        'timestamp': FieldValue.serverTimestamp(),
        'environment': EnvironmentConfig.currentEnvironment.name,
      });
      
      // Execute unpause through contract
      await _contractService.unpauseContract(contractAddress);
      
      _logGovernance('✅ Emergency unpause executed for $contractAddress: $reason');
      
    } catch (e) {
      _logGovernanceError('Failed to execute emergency unpause: $e');
      rethrow;
    }
  }
  
  /// Get active proposals
  Future<List<GovernanceProposal>> getActiveProposals() async {
    try {
      final now = DateTime.now();
      
      final query = await _firestore
          .collection('governance_proposals')
          .where('status', whereIn: ['pending', 'active'])
          .orderBy('createdAt', descending: true)
          .get();
      
      final proposals = <GovernanceProposal>[];
      
      for (final doc in query.docs) {
        final proposal = GovernanceProposal.fromMap(doc.data());
        
        // Update status based on current time
        ProposalStatus currentStatus = proposal.status;
        
        if (proposal.status == ProposalStatus.pending && now.isAfter(proposal.votingStartsAt)) {
          currentStatus = ProposalStatus.active;
        } else if (proposal.status == ProposalStatus.active && now.isAfter(proposal.votingEndsAt)) {
          currentStatus = await _determineProposalOutcome(proposal);
        }
        
        if (currentStatus != proposal.status) {
          await _firestore.collection('governance_proposals').doc(proposal.id).update({
            'status': currentStatus.name,
          });
        }
        
        proposals.add(proposal.copyWith(status: currentStatus));
      }
      
      return proposals;
      
    } catch (e) {
      _logGovernanceError('Failed to get active proposals: $e');
      return [];
    }
  }
  
  /// Get governance dashboard data
  Future<GovernanceDashboard> getDashboardData() async {
    try {
      final now = DateTime.now();
      const thirtyDaysAgo = Duration(days: 30);
      
      // Get proposal statistics
      final allProposals = await _firestore
          .collection('governance_proposals')
          .where('createdAt', isGreaterThan: now.subtract(thirtyDaysAgo))
          .get();
      
      final proposalStats = <String, int>{};
      for (final doc in allProposals.docs) {
        final status = doc.data()['status'] as String;
        proposalStats[status] = (proposalStats[status] ?? 0) + 1;
      }
      
      // Get voting participation
      final allVotes = await _firestore
          .collection('governance_votes')
          .where('timestamp', isGreaterThan: now.subtract(thirtyDaysAgo))
          .get();
      
      final uniqueVoters = <String>{};
      double totalVotingPower = 0;
      
      for (final doc in allVotes.docs) {
        uniqueVoters.add(doc.data()['voter']);
        totalVotingPower += doc.data()['votingPower'];
      }
      
      // Get emergency actions
      final emergencyActions = await _firestore
          .collection('emergency_actions')
          .where('timestamp', isGreaterThan: now.subtract(thirtyDaysAgo))
          .get();
      
      return GovernanceDashboard(
        totalProposals: allProposals.docs.length,
        proposalStats: proposalStats,
        uniqueVoters: uniqueVoters.length,
        totalVotingPower: totalVotingPower,
        emergencyActions: emergencyActions.docs.length,
        averageParticipation: uniqueVoters.isNotEmpty ? totalVotingPower / uniqueVoters.length : 0,
        lastUpdated: now,
      );
      
    } catch (e) {
      _logGovernanceError('Failed to get dashboard data: $e');
      return GovernanceDashboard.empty();
    }
  }
  
  // Private methods
  
  Future<void> _initializeGovernanceContracts() async {
    // Initialize governance contract addresses
    await _firestore.collection('governance_config').doc('contracts').set({
      'multisigAddress': EnvironmentConfig.smartContractConfig['multisigAddress'],
      'timelockAddress': EnvironmentConfig.smartContractConfig['timelockAddress'],
      'governorAddress': EnvironmentConfig.smartContractConfig['governorAddress'],
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
  
  Future<void> _loadGovernanceState() async {
    // Load current governance state
    final configDoc = await _firestore.collection('governance_config').doc('parameters').get();
    
    if (!configDoc.exists) {
      // Initialize default parameters
      await _firestore.collection('governance_config').doc('parameters').set({
        'minProposalThreshold': MIN_PROPOSAL_THRESHOLD,
        'votingPeriodDays': VOTING_PERIOD.inDays,
        'timelockDelayDays': TIMELOCK_DELAY.inDays,
        'quorumThreshold': QUORUM_THRESHOLD,
        'approvalThreshold': APPROVAL_THRESHOLD,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }
  
  Future<void> _scheduleGovernanceTasks() async {
    // Schedule periodic tasks
    Timer.periodic(const Duration(hours: 1), (timer) async {
      await _updateProposalStatuses();
    });
    
    Timer.periodic(const Duration(hours: 6), (timer) async {
      await _processExecutableProposals();
    });
  }
  
  String _generateProposalId() {
    return 'prop_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  Future<void> _lockProposerTokens(String proposer, int amount, DateTime unlockDate) async {
    await _firestore.collection('locked_tokens').add({
      'owner': proposer,
      'amount': amount,
      'lockReason': 'governance_proposal',
      'lockedAt': FieldValue.serverTimestamp(),
      'unlockDate': unlockDate,
      'status': 'locked',
    });
    
    // Call smart contract to lock tokens
    await _contractService.lockTokens(proposer, amount, unlockDate);
  }
  
  Future<void> _unlockProposerTokens(String proposer, int amount) async {
    final lockedTokensQuery = await _firestore
        .collection('locked_tokens')
        .where('owner', isEqualTo: proposer)
        .where('amount', isEqualTo: amount)
        .where('status', isEqualTo: 'locked')
        .get();
    
    for (final doc in lockedTokensQuery.docs) {
      await doc.reference.update({
        'status': 'unlocked',
        'unlockedAt': FieldValue.serverTimestamp(),
      });
    }
    
    // Call smart contract to unlock tokens
    await _contractService.unlockTokens(proposer, amount);
  }
  
  Future<double> _getVoterBalanceAtSnapshot(String voter, DateTime snapshotTime) async {
    // In a real implementation, this would query historical balance
    // For now, return current balance
    return await _contractService.getCNEBalance(voter);
  }
  
  Future<void> _validateProposalForExecution(GovernanceProposal proposal) async {
    if (proposal.status != ProposalStatus.approved) {
      throw GovernanceException('Proposal is not approved for execution');
    }
    
    final totalSupply = await _contractService.getTotalCNESupply();
    final quorum = totalSupply * QUORUM_THRESHOLD;
    
    if (proposal.totalVotes < quorum) {
      throw GovernanceException('Proposal did not meet quorum threshold');
    }
    
    final approvalRate = proposal.votesFor / proposal.totalVotes;
    if (approvalRate < APPROVAL_THRESHOLD) {
      throw GovernanceException('Proposal did not meet approval threshold');
    }
  }
  
  Future<Map<String, dynamic>> _executeContractUpgrade(GovernanceProposal proposal) async {
    try {
      // Execute the contract upgrade
      final result = await _contractService.upgradeContract(
        contractAddress: proposal.contractToUpgrade,
        newImplementation: proposal.newImplementationAddress,
        upgradeData: proposal.upgradeParameters,
      );
      
      return {
        'success': true,
        'transactionHash': result['transactionHash'],
        'gasUsed': result['gasUsed'],
        'executedAt': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'executedAt': DateTime.now().toIso8601String(),
      };
    }
  }
  
  Future<ProposalStatus> _determineProposalOutcome(GovernanceProposal proposal) async {
    final totalSupply = await _contractService.getTotalCNESupply();
    final quorum = totalSupply * QUORUM_THRESHOLD;
    
    if (proposal.totalVotes < quorum) {
      return ProposalStatus.failed;
    }
    
    final approvalRate = proposal.votesFor / proposal.totalVotes;
    if (approvalRate >= APPROVAL_THRESHOLD) {
      return ProposalStatus.approved;
    } else {
      return ProposalStatus.rejected;
    }
  }
  
  Future<void> _updateProposalStatuses() async {
    final activeProposals = await getActiveProposals();
    // Status updates are handled in getActiveProposals()
  }
  
  Future<void> _processExecutableProposals() async {
    final now = DateTime.now();
    
    final executableProposals = await _firestore
        .collection('governance_proposals')
        .where('status', isEqualTo: 'approved')
        .get();
    
    for (final doc in executableProposals.docs) {
      final proposal = GovernanceProposal.fromMap(doc.data());
      
      if (now.isAfter(proposal.votingEndsAt.add(TIMELOCK_DELAY))) {
        try {
          await executeProposal(proposal.id);
        } catch (e) {
          _logGovernanceError('Auto-execution failed for ${proposal.id}: $e');
        }
      }
    }
  }
  
  void _logGovernance(String message) {
    if (EnvironmentConfig.securityConfig['allowDebugLogs']) {
      print('🏛️ Governance: $message');
    }
  }
  
  void _logGovernanceError(String message) {
    print('❌ Governance Error: $message');
  }
}

/// Governance proposal model
class GovernanceProposal {
  final String id;
  final String title;
  final String description;
  final String proposer;
  final String contractToUpgrade;
  final String newImplementationAddress;
  final Map<String, dynamic> upgradeParameters;
  final DateTime createdAt;
  final DateTime votingStartsAt;
  final DateTime votingEndsAt;
  final ProposalStatus status;
  final double votesFor;
  final double votesAgainst;
  final double totalVotes;
  
  GovernanceProposal({
    required this.id,
    required this.title,
    required this.description,
    required this.proposer,
    required this.contractToUpgrade,
    required this.newImplementationAddress,
    required this.upgradeParameters,
    required this.createdAt,
    required this.votingStartsAt,
    required this.votingEndsAt,
    required this.status,
    required this.votesFor,
    required this.votesAgainst,
    required this.totalVotes,
  });
  
  GovernanceProposal copyWith({
    String? id,
    String? title,
    String? description,
    String? proposer,
    String? contractToUpgrade,
    String? newImplementationAddress,
    Map<String, dynamic>? upgradeParameters,
    DateTime? createdAt,
    DateTime? votingStartsAt,
    DateTime? votingEndsAt,
    ProposalStatus? status,
    double? votesFor,
    double? votesAgainst,
    double? totalVotes,
  }) {
    return GovernanceProposal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      proposer: proposer ?? this.proposer,
      contractToUpgrade: contractToUpgrade ?? this.contractToUpgrade,
      newImplementationAddress: newImplementationAddress ?? this.newImplementationAddress,
      upgradeParameters: upgradeParameters ?? this.upgradeParameters,
      createdAt: createdAt ?? this.createdAt,
      votingStartsAt: votingStartsAt ?? this.votingStartsAt,
      votingEndsAt: votingEndsAt ?? this.votingEndsAt,
      status: status ?? this.status,
      votesFor: votesFor ?? this.votesFor,
      votesAgainst: votesAgainst ?? this.votesAgainst,
      totalVotes: totalVotes ?? this.totalVotes,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'proposer': proposer,
      'contractToUpgrade': contractToUpgrade,
      'newImplementationAddress': newImplementationAddress,
      'upgradeParameters': upgradeParameters,
      'createdAt': createdAt.toIso8601String(),
      'votingStartsAt': votingStartsAt.toIso8601String(),
      'votingEndsAt': votingEndsAt.toIso8601String(),
      'status': status.name,
      'votesFor': votesFor,
      'votesAgainst': votesAgainst,
      'totalVotes': totalVotes,
    };
  }
  
  factory GovernanceProposal.fromMap(Map<String, dynamic> map) {
    return GovernanceProposal(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      proposer: map['proposer'],
      contractToUpgrade: map['contractToUpgrade'],
      newImplementationAddress: map['newImplementationAddress'],
      upgradeParameters: Map<String, dynamic>.from(map['upgradeParameters']),
      createdAt: DateTime.parse(map['createdAt']),
      votingStartsAt: DateTime.parse(map['votingStartsAt']),
      votingEndsAt: DateTime.parse(map['votingEndsAt']),
      status: ProposalStatus.values.firstWhere((e) => e.name == map['status']),
      votesFor: map['votesFor'].toDouble(),
      votesAgainst: map['votesAgainst'].toDouble(),
      totalVotes: map['totalVotes'].toDouble(),
    );
  }
}

/// Proposal status enum
enum ProposalStatus {
  pending,
  active,
  approved,
  rejected,
  failed,
  executed,
}

/// Governance dashboard data
class GovernanceDashboard {
  final int totalProposals;
  final Map<String, int> proposalStats;
  final int uniqueVoters;
  final double totalVotingPower;
  final int emergencyActions;
  final double averageParticipation;
  final DateTime lastUpdated;
  
  GovernanceDashboard({
    required this.totalProposals,
    required this.proposalStats,
    required this.uniqueVoters,
    required this.totalVotingPower,
    required this.emergencyActions,
    required this.averageParticipation,
    required this.lastUpdated,
  });
  
  factory GovernanceDashboard.empty() {
    return GovernanceDashboard(
      totalProposals: 0,
      proposalStats: {},
      uniqueVoters: 0,
      totalVotingPower: 0,
      emergencyActions: 0,
      averageParticipation: 0,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Governance-specific exceptions
class GovernanceException implements Exception {
  final String message;
  GovernanceException(this.message);
  
  @override
  String toString() => 'GovernanceException: $message';
}
