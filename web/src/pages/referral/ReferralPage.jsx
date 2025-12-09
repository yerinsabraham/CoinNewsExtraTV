import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import {
  getReferralStats,
  getReferredUsers,
  initializeReferralCode,
  getReferralBonuses
} from '../../services/referral.service';
import { ArrowLeft, Copy, Users, Gift, TrendingUp, CheckCircle2, Info } from 'lucide-react';
import toast from 'react-hot-toast';

/**
 * ReferralPage - Referral System
 * Share referral code and earn rewards
 */
const ReferralPage = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  
  const [stats, setStats] = useState(null);
  const [referredUsers, setReferredUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [copied, setCopied] = useState(false);
  
  const bonuses = getReferralBonuses();
  const referralLink = stats?.referralCode 
    ? `${window.location.origin}/signup?ref=${stats.referralCode}`
    : '';
  
  useEffect(() => {
    if (user) {
      loadReferralData();
    }
  }, [user]);
  
  const loadReferralData = async () => {
    try {
      setLoading(true);
      
      // Initialize referral code if not exists
      let referralCode = user.referralCode;
      if (!referralCode) {
        referralCode = await initializeReferralCode(user.uid, user.displayName);
      }
      
      const [statsData, usersData] = await Promise.all([
        getReferralStats(user.uid),
        getReferredUsers(user.uid)
      ]);
      
      setStats(statsData);
      setReferredUsers(usersData);
    } catch (error) {
      console.error('Error loading referral data:', error);
      toast.error('Failed to load referral data');
    } finally {
      setLoading(false);
    }
  };
  
  const handleCopyCode = () => {
    if (stats?.referralCode) {
      navigator.clipboard.writeText(stats.referralCode);
      setCopied(true);
      toast.success('Referral code copied!');
      setTimeout(() => setCopied(false), 2000);
    }
  };
  
  const handleCopyLink = () => {
    if (referralLink) {
      navigator.clipboard.writeText(referralLink);
      toast.success('Referral link copied!');
    }
  };
  
  const handleShare = () => {
    if (navigator.share && referralLink) {
      navigator.share({
        title: 'Join CNE Watch2Earn',
        text: `Use my referral code ${stats.referralCode} to get ${bonuses.refereeBonus} CNE bonus!`,
        url: referralLink
      }).catch(err => console.log('Error sharing:', err));
    } else {
      handleCopyLink();
    }
  };
  
  if (loading) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin w-16 h-16 border-4 border-primary border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-gray-400">Loading referral data...</p>
        </div>
      </div>
    );
  }
  
  return (
    <div className="min-h-screen bg-dark-bg pb-20">
      {/* Header */}
      <div className="bg-gradient-to-r from-primary to-green-600 text-white p-6">
        <div className="max-w-7xl mx-auto">
          <button
            onClick={() => navigate('/')}
            className="flex items-center gap-2 text-white/90 hover:text-white mb-4 transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            Back to Home
          </button>
          
          <div>
            <h1 className="text-3xl font-bold flex items-center gap-3">
              <Users className="w-8 h-8" />
              Referral Program
            </h1>
            <p className="text-white/90 mt-2">
              Invite friends and earn {bonuses.referrerBonus} CNE per referral!
            </p>
          </div>
        </div>
      </div>
      
      <div className="max-w-4xl mx-auto px-4 py-8">
        {/* Info Banner */}
        <div className="bg-blue-500/10 border border-blue-500/30 rounded-lg p-4 mb-8 flex items-start gap-3">
          <Info className="w-5 h-5 text-blue-400 flex-shrink-0 mt-0.5" />
          <div className="text-sm text-gray-300">
            <p className="font-semibold text-white mb-1">How it works:</p>
            <ul className="list-disc list-inside space-y-1 text-gray-400">
              <li>Share your referral code with friends</li>
              <li>They get {bonuses.refereeBonus} CNE when they sign up</li>
              <li>You get {bonuses.referrerBonus} CNE for each successful referral</li>
              <li>No limit on referrals - invite as many as you want!</li>
            </ul>
          </div>
        </div>
        
        {/* Referral Code Card */}
        <div className="bg-gradient-to-br from-primary/20 to-green-600/20 border-2 border-primary rounded-xl p-8 mb-8">
          <div className="text-center mb-6">
            <p className="text-gray-400 mb-2">Your Referral Code</p>
            <div className="bg-dark-bg rounded-lg px-6 py-4 mb-4">
              <p className="text-4xl font-bold text-white tracking-wider">
                {stats?.referralCode || 'Loading...'}
              </p>
            </div>
            
            <div className="flex gap-3 justify-center">
              <button
                onClick={handleCopyCode}
                className="flex items-center gap-2 bg-primary hover:bg-primary/90 text-white px-6 py-3 rounded-lg font-semibold transition-colors"
              >
                {copied ? (
                  <>
                    <CheckCircle2 className="w-5 h-5" />
                    Copied!
                  </>
                ) : (
                  <>
                    <Copy className="w-5 h-5" />
                    Copy Code
                  </>
                )}
              </button>
              
              <button
                onClick={handleShare}
                className="flex items-center gap-2 bg-green-600 hover:bg-green-700 text-white px-6 py-3 rounded-lg font-semibold transition-colors"
              >
                <Gift className="w-5 h-5" />
                Share
              </button>
            </div>
          </div>
          
          {/* Referral Link */}
          <div className="bg-dark-bg/50 rounded-lg p-4">
            <p className="text-sm text-gray-400 mb-2">Referral Link:</p>
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={referralLink}
                readOnly
                className="flex-1 bg-dark-card border border-dark-border rounded px-3 py-2 text-sm text-gray-300 focus:outline-none"
              />
              <button
                onClick={handleCopyLink}
                className="p-2 bg-primary/20 hover:bg-primary/30 rounded transition-colors"
              >
                <Copy className="w-5 h-5 text-primary" />
              </button>
            </div>
          </div>
        </div>
        
        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
          <div className="bg-dark-card rounded-lg p-6">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-12 h-12 rounded-lg bg-blue-500/10 flex items-center justify-center">
                <Users className="w-6 h-6 text-blue-400" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Total Referrals</p>
                <p className="text-3xl font-bold text-white">{stats?.totalReferrals || 0}</p>
              </div>
            </div>
          </div>
          
          <div className="bg-dark-card rounded-lg p-6">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-12 h-12 rounded-lg bg-green-500/10 flex items-center justify-center">
                <TrendingUp className="w-6 h-6 text-green-400" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Total Earned</p>
                <p className="text-3xl font-bold text-green-400">{stats?.totalEarned || 0} CNE</p>
              </div>
            </div>
          </div>
          
          <div className="bg-dark-card rounded-lg p-6">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-12 h-12 rounded-lg bg-purple-500/10 flex items-center justify-center">
                <Gift className="w-6 h-6 text-purple-400" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Active Referrals</p>
                <p className="text-3xl font-bold text-white">{stats?.activeReferrals || 0}</p>
              </div>
            </div>
          </div>
        </div>
        
        {/* Referred Users List */}
        <div className="bg-dark-card rounded-lg p-6">
          <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
            <Users className="w-5 h-5" />
            Your Referrals
          </h3>
          
          {referredUsers.length === 0 ? (
            <div className="text-center py-12">
              <Users className="w-16 h-16 text-gray-600 mx-auto mb-4" />
              <p className="text-gray-400 text-lg mb-2">No referrals yet</p>
              <p className="text-gray-500 text-sm">Share your code to start earning!</p>
            </div>
          ) : (
            <div className="space-y-3">
              {referredUsers.map((referral) => (
                <div
                  key={referral.id}
                  className="bg-dark-bg rounded-lg p-4 flex items-center justify-between"
                >
                  <div className="flex items-center gap-3">
                    {referral.userPhoto ? (
                      <img
                        src={referral.userPhoto}
                        alt={referral.userName}
                        className="w-12 h-12 rounded-full object-cover"
                      />
                    ) : (
                      <div className="w-12 h-12 rounded-full bg-primary flex items-center justify-center text-white font-bold">
                        {referral.userName?.[0]?.toUpperCase() || '?'}
                      </div>
                    )}
                    <div>
                      <p className="font-semibold text-white">{referral.userName}</p>
                      <p className="text-sm text-gray-400">
                        Joined {referral.joinedAt?.toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                  
                  <div className="text-right">
                    <p className="text-green-400 font-bold">+{referral.bonus} CNE</p>
                    <p className="text-xs text-gray-500">Earned</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ReferralPage;
