import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import {
  getCheckinData,
  processCheckin,
  getCheckinHistory,
  getCheckinStats,
  getCheckinCalendar,
  getNextStreakMilestone,
  getStreakBonuses
} from '../../services/checkin.service';
import CheckinCalendar from '../../components/checkin/CheckinCalendar';
import CheckinStats from '../../components/checkin/CheckinStats';
import CheckinHistory from '../../components/checkin/CheckinHistory';
import { ArrowLeft, CheckCircle2, Gift, Info, Sparkles } from 'lucide-react';
import toast from 'react-hot-toast';

/**
 * CheckinPage - Daily Check-in System
 * Daily check-ins with streak tracking and bonus rewards
 */
const CheckinPage = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  
  const [checkinData, setCheckinData] = useState(null);
  const [stats, setStats] = useState({});
  const [history, setHistory] = useState([]);
  const [calendar, setCalendar] = useState({});
  const [loading, setLoading] = useState(true);
  const [checkingIn, setCheckingIn] = useState(false);
  const [showRewardModal, setShowRewardModal] = useState(false);
  const [lastCheckinResult, setLastCheckinResult] = useState(null);
  
  const streakBonuses = getStreakBonuses();
  
  // Load check-in data
  useEffect(() => {
    if (user) {
      loadCheckinData();
    }
  }, [user]);
  
  const loadCheckinData = async () => {
    try {
      setLoading(true);
      const today = new Date();
      const [data, statsData, historyData, calendarData] = await Promise.all([
        getCheckinData(user.uid),
        getCheckinStats(user.uid),
        getCheckinHistory(user.uid, 20),
        getCheckinCalendar(user.uid, today.getFullYear(), today.getMonth())
      ]);
      
      setCheckinData(data);
      setStats(statsData);
      setHistory(historyData);
      setCalendar(calendarData);
    } catch (error) {
      console.error('Error loading check-in data:', error);
      toast.error('Failed to load check-in data');
    } finally {
      setLoading(false);
    }
  };
  
  const handleMonthChange = async (year, month) => {
    try {
      const calendarData = await getCheckinCalendar(user.uid, year, month);
      setCalendar(calendarData);
    } catch (error) {
      console.error('Error loading calendar:', error);
    }
  };
  
  const handleCheckin = async () => {
    if (!user || checkingIn || !checkinData?.canCheckIn) return;
    
    setCheckingIn(true);
    
    try {
      const result = await processCheckin(user.uid);
      
      // Show success
      setLastCheckinResult(result);
      setShowRewardModal(true);
      
      // Reload data
      await loadCheckinData();
      
      if (result.isStreakBonus) {
        toast.success(`🎉 ${result.streak}-Day Streak Bonus: +${result.bonusReward} CNE!`, {
          duration: 5000
        });
      } else {
        toast.success(`Check-in successful! +${result.totalReward} CNE`, {
          icon: '✅',
          duration: 4000
        });
      }
    } catch (error) {
      console.error('Error processing check-in:', error);
      toast.error(error.message || 'Failed to process check-in');
    } finally {
      setCheckingIn(false);
    }
  };
  
  if (loading) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin w-16 h-16 border-4 border-primary border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-gray-400">Loading check-in data...</p>
        </div>
      </div>
    );
  }
  
  const nextMilestone = getNextStreakMilestone(stats.currentStreak || 0);
  
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
          
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold flex items-center gap-3">
                <CheckCircle2 className="w-8 h-8" />
                Daily Check-in
              </h1>
              <p className="text-white/90 mt-2">
                Check in every day to earn 28 CNE and build your streak!
              </p>
            </div>
            
            {checkinData?.canCheckIn && (
              <div className="text-right">
                <p className="text-white/90 text-sm mb-2">Today's Reward</p>
                <div className="bg-white/20 rounded-lg px-6 py-3">
                  <p className="text-3xl font-bold">28 CNE</p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
      
      <div className="max-w-7xl mx-auto px-4 py-8">
        {/* Info Banner */}
        <div className="bg-blue-500/10 border border-blue-500/30 rounded-lg p-4 mb-8 flex items-start gap-3">
          <Info className="w-5 h-5 text-blue-400 flex-shrink-0 mt-0.5" />
          <div className="text-sm text-gray-300">
            <p className="font-semibold text-white mb-1">How it works:</p>
            <ul className="list-disc list-inside space-y-1 text-gray-400">
              <li>Check in daily to earn 28 CNE</li>
              <li>Build streaks for bonus rewards (7, 14, 21, 28, 30 days)</li>
              <li>Miss a day and your streak resets</li>
              <li>Keep your streak alive for maximum rewards!</li>
            </ul>
          </div>
        </div>
        
        {/* Check-in Button */}
        <div className="flex justify-center mb-8">
          <button
            onClick={handleCheckin}
            disabled={!checkinData?.canCheckIn || checkingIn}
            className={`
              px-12 py-6 rounded-2xl font-bold text-2xl shadow-2xl
              transition-all duration-300 transform
              flex items-center gap-4
              ${!checkinData?.canCheckIn || checkingIn
                ? 'bg-gray-400 cursor-not-allowed opacity-50'
                : 'bg-gradient-to-r from-green-400 via-primary to-green-600 text-white hover:scale-105 hover:shadow-3xl animate-pulse'
              }
            `}
          >
            {checkingIn ? (
              <>
                <div className="animate-spin w-8 h-8 border-4 border-white border-t-transparent rounded-full" />
                CHECKING IN...
              </>
            ) : checkinData?.canCheckIn ? (
              <>
                <CheckCircle2 className="w-8 h-8" />
                CHECK IN NOW
                <Sparkles className="w-8 h-8" />
              </>
            ) : (
              <>
                <CheckCircle2 className="w-8 h-8" />
                CHECKED IN TODAY ✓
              </>
            )}
          </button>
        </div>
        
        {/* Streak Bonuses Info */}
        <div className="bg-gradient-to-r from-purple-500/10 to-pink-500/10 border border-purple-500/30 rounded-lg p-6 mb-8">
          <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
            <Gift className="w-6 h-6 text-purple-400" />
            Streak Bonus Rewards
          </h3>
          
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            {Object.entries(streakBonuses).map(([days, reward]) => {
              const achieved = (stats.currentStreak || 0) >= parseInt(days);
              return (
                <div
                  key={days}
                  className={`
                    rounded-lg p-4 text-center transition-all
                    ${achieved 
                      ? 'bg-primary/20 border-2 border-primary' 
                      : 'bg-dark-card border border-dark-border'
                    }
                  `}
                >
                  <p className={`text-2xl font-bold mb-1 ${achieved ? 'text-white' : 'text-gray-400'}`}>
                    {days}
                  </p>
                  <p className="text-xs text-gray-400 mb-2">days</p>
                  <p className={`font-bold ${achieved ? 'text-green-400' : 'text-gray-400'}`}>
                    +{reward} CNE
                  </p>
                  {achieved && (
                    <p className="text-xs text-primary mt-1">✓ Earned</p>
                  )}
                </div>
              );
            })}
          </div>
        </div>
        
        {/* Stats */}
        <div className="mb-8">
          <CheckinStats stats={stats} nextMilestone={nextMilestone} />
        </div>
        
        {/* Calendar */}
        <div className="mb-8">
          <CheckinCalendar 
            checkins={calendar} 
            onMonthChange={handleMonthChange}
          />
        </div>
        
        {/* History */}
        <CheckinHistory history={history} />
      </div>
      
      {/* Reward Modal */}
      {showRewardModal && lastCheckinResult && (
        <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4">
          <div className="bg-dark-card rounded-2xl p-8 max-w-md w-full text-center animate-bounce-in">
            <div className="mb-6">
              <div className="w-32 h-32 bg-gradient-to-br from-green-400 to-primary rounded-full mx-auto flex items-center justify-center text-white text-5xl font-bold shadow-2xl animate-pulse">
                ✓
              </div>
            </div>
            
            <h2 className="text-3xl font-bold text-white mb-2">
              Check-in Successful! 🎉
            </h2>
            
            <p className="text-xl text-gray-300 mb-6">
              You earned <span className="text-green-400 font-bold">+{lastCheckinResult.totalReward} CNE</span>!
            </p>
            
            {lastCheckinResult.isStreakBonus && (
              <div className="bg-gradient-to-r from-purple-500/20 to-pink-500/20 border border-purple-500/30 rounded-lg p-4 mb-6">
                <p className="text-purple-400 font-bold mb-2">🎊 Streak Bonus!</p>
                <p className="text-white">
                  {lastCheckinResult.streak} Day Streak: <span className="text-green-400">+{lastCheckinResult.bonusReward} CNE</span>
                </p>
              </div>
            )}
            
            <div className="bg-dark-bg rounded-lg p-4 mb-6 space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-400">Base Reward</span>
                <span className="text-white font-semibold">+{lastCheckinResult.baseReward} CNE</span>
              </div>
              
              {lastCheckinResult.bonusReward > 0 && (
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-400">Streak Bonus</span>
                  <span className="text-purple-400 font-semibold">+{lastCheckinResult.bonusReward} CNE</span>
                </div>
              )}
              
              <div className="border-t border-dark-border pt-2 flex items-center justify-between">
                <span className="text-gray-400">New Balance</span>
                <span className="text-xl font-bold text-white">
                  {lastCheckinResult.newBalance?.toLocaleString()} CNE
                </span>
              </div>
            </div>
            
            <div className="bg-orange-500/10 border border-orange-500/30 rounded-lg p-3 mb-6">
              <p className="text-sm text-orange-400">
                🔥 Current Streak: <span className="font-bold">{lastCheckinResult.streak} {lastCheckinResult.streak === 1 ? 'day' : 'days'}</span>
              </p>
              <p className="text-xs text-gray-400 mt-1">
                Come back tomorrow to keep your streak!
              </p>
            </div>
            
            <button
              onClick={() => setShowRewardModal(false)}
              className="w-full bg-primary hover:bg-primary/90 text-white py-3 rounded-lg font-semibold transition-colors"
            >
              Awesome!
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default CheckinPage;
