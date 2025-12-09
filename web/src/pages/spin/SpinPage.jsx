import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { 
  getTodaySpinData, 
  processSpin, 
  getSpinHistory, 
  getSpinStats, 
  getRewardSegments,
  getTimeUntilReset 
} from '../../services/spin.service';
import SpinWheel from '../../components/spin/SpinWheel';
import SpinHistory from '../../components/spin/SpinHistory';
import SpinStats from '../../components/spin/SpinStats';
import { ArrowLeft, Clock, Sparkles, Trophy, Info } from 'lucide-react';
import toast from 'react-hot-toast';

/**
 * SpinPage - Spin2Earn Wheel
 * Daily spinning wheel with rewards from 10-1000 CNE
 */
const SpinPage = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  
  const [spinData, setSpinData] = useState(null);
  const [history, setHistory] = useState([]);
  const [stats, setStats] = useState({});
  const [loading, setLoading] = useState(true);
  const [spinning, setSpinning] = useState(false);
  const [timeUntilReset, setTimeUntilReset] = useState(getTimeUntilReset());
  const [showRewardModal, setShowRewardModal] = useState(false);
  const [lastReward, setLastReward] = useState(null);
  
  const segments = getRewardSegments();
  
  // Load spin data, history, and stats
  useEffect(() => {
    if (user) {
      loadSpinData();
    }
  }, [user]);
  
  // Update countdown timer
  useEffect(() => {
    const timer = setInterval(() => {
      setTimeUntilReset(getTimeUntilReset());
    }, 1000);
    
    return () => clearInterval(timer);
  }, []);
  
  const loadSpinData = async () => {
    try {
      setLoading(true);
      const [data, historyData, statsData] = await Promise.all([
        getTodaySpinData(user.uid),
        getSpinHistory(user.uid, 10),
        getSpinStats(user.uid)
      ]);
      
      setSpinData(data);
      setHistory(historyData);
      setStats(statsData);
    } catch (error) {
      console.error('Error loading spin data:', error);
      toast.error('Failed to load spin data');
    } finally {
      setLoading(false);
    }
  };
  
  const handleSpin = async () => {
    if (!user || spinning || spinData?.spinsRemaining <= 0) return;
    
    setSpinning(true);
    
    try {
      // Generate reward first so wheel knows what to land on
      const result = await processSpin(user.uid);
      
      // Show success
      setLastReward(result);
      setShowRewardModal(true);
      
      // Reload data
      await loadSpinData();
      
      toast.success(`You won ${result.reward.value} CNE!`, {
        icon: '🎉',
        duration: 5000
      });
    } catch (error) {
      console.error('Error processing spin:', error);
      toast.error(error.message || 'Failed to process spin');
    } finally {
      setSpinning(false);
    }
  };
  
  const handleSpinComplete = (segment) => {
    // This is called after the wheel animation completes
    console.log('Wheel stopped on:', segment);
  };
  
  if (loading) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin w-16 h-16 border-4 border-primary border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-gray-400">Loading spin wheel...</p>
        </div>
      </div>
    );
  }
  
  const canSpin = spinData?.spinsRemaining > 0;
  
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
                <Sparkles className="w-8 h-8" />
                Spin2Earn Wheel
              </h1>
              <p className="text-white/90 mt-2">
                Spin daily and win up to 1000 CNE!
              </p>
            </div>
            
            <div className="text-right">
              <p className="text-white/90 text-sm">Spins Remaining Today</p>
              <p className="text-4xl font-bold">{spinData?.spinsRemaining || 0}/3</p>
            </div>
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
              <li>Get 3 free spins every day</li>
              <li>Win anywhere from 10 to 1000 CNE per spin</li>
              <li>Spins reset daily at midnight</li>
              <li>The more you spin, the better your chances!</li>
            </ul>
          </div>
        </div>
        
        {/* Reset Timer */}
        {!canSpin && (
          <div className="bg-orange-500/10 border border-orange-500/30 rounded-lg p-4 mb-8 text-center">
            <Clock className="w-8 h-8 text-orange-400 mx-auto mb-2" />
            <p className="text-white font-semibold mb-1">Out of spins today</p>
            <p className="text-orange-400">
              Next reset in: {String(timeUntilReset.hours).padStart(2, '0')}:
              {String(timeUntilReset.minutes).padStart(2, '0')}:
              {String(timeUntilReset.seconds).padStart(2, '0')}
            </p>
          </div>
        )}
        
        {/* Spin Wheel */}
        <div className="mb-8 flex justify-center">
          <SpinWheel
            segments={segments}
            onSpinComplete={handleSpinComplete}
            disabled={!canSpin || spinning}
          />
        </div>
        
        {/* Spin Button Below Wheel */}
        <div className="flex justify-center mb-8">
          <button
            onClick={handleSpin}
            disabled={!canSpin || spinning}
            className={`
              px-12 py-5 rounded-full font-bold text-2xl shadow-xl
              transition-all duration-300 transform
              flex items-center gap-4
              ${!canSpin || spinning
                ? 'bg-gray-400 cursor-not-allowed opacity-50'
                : 'bg-gradient-to-r from-yellow-400 via-orange-500 to-red-500 text-white hover:scale-110 hover:shadow-2xl animate-pulse'
              }
            `}
          >
            <Trophy className={`w-8 h-8 ${spinning ? 'animate-spin' : ''}`} />
            {spinning ? 'SPINNING...' : canSpin ? 'SPIN TO WIN!' : 'NO SPINS LEFT'}
            <Trophy className={`w-8 h-8 ${spinning ? 'animate-spin' : ''}`} />
          </button>
        </div>
        
        {/* Stats */}
        <div className="mb-8">
          <SpinStats stats={stats} />
        </div>
        
        {/* History */}
        <SpinHistory history={history} />
      </div>
      
      {/* Reward Modal */}
      {showRewardModal && lastReward && (
        <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4">
          <div className="bg-dark-card rounded-2xl p-8 max-w-md w-full text-center animate-bounce-in">
            <div className="mb-6">
              <div
                className="w-32 h-32 rounded-full mx-auto flex items-center justify-center text-white text-4xl font-bold shadow-2xl animate-pulse"
                style={{ backgroundColor: lastReward.reward.color }}
              >
                {lastReward.reward.value}
              </div>
            </div>
            
            <h2 className="text-3xl font-bold text-white mb-2">
              Congratulations! 🎉
            </h2>
            
            <p className="text-xl text-gray-300 mb-6">
              You won <span className="text-green-400 font-bold">{lastReward.reward.label}</span>!
            </p>
            
            <div className="bg-dark-bg rounded-lg p-4 mb-6">
              <p className="text-sm text-gray-400 mb-1">New Balance</p>
              <p className="text-2xl font-bold text-white">
                {lastReward.newBalance?.toLocaleString()} CNE
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

export default SpinPage;
