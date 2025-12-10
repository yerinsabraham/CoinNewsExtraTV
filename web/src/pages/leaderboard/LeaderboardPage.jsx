import React, { useState, useEffect } from 'react';
import { Trophy, RefreshCw, Filter } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { getLeaderboard, getUserRank, TIME_PERIODS } from '../../services/leaderboard.service';
import LeaderboardCard from '../../components/leaderboard/LeaderboardCard';
import UserRankCard from '../../components/leaderboard/UserRankCard';
import { toast } from 'react-hot-toast';

const LeaderboardPage = () => {
  const { user } = useAuth();
  const [leaderboard, setLeaderboard] = useState([]);
  const [userRank, setUserRank] = useState(null);
  const [selectedPeriod, setSelectedPeriod] = useState(TIME_PERIODS.ALL_TIME);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const periods = [
    { value: TIME_PERIODS.DAILY, label: 'Daily', emoji: '📅' },
    { value: TIME_PERIODS.WEEKLY, label: 'Weekly', emoji: '📆' },
    { value: TIME_PERIODS.MONTHLY, label: 'Monthly', emoji: '🗓️' },
    { value: TIME_PERIODS.ALL_TIME, label: 'All Time', emoji: '🏆' }
  ];

  useEffect(() => {
    loadLeaderboard();
  }, [selectedPeriod, user]);

  const loadLeaderboard = async () => {
    try {
      setLoading(true);
      
      // Load leaderboard data
      const data = await getLeaderboard(selectedPeriod, 50);
      setLeaderboard(data);

      // Load user's rank if authenticated
      if (user) {
        const rank = await getUserRank(user.uid, selectedPeriod);
        setUserRank(rank);
      }
    } catch (error) {
      console.error('Error loading leaderboard:', error);
      toast.error('Failed to load leaderboard');
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadLeaderboard();
    setRefreshing(false);
    toast.success('Leaderboard refreshed!');
  };

  const handlePeriodChange = (period) => {
    setSelectedPeriod(period);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 py-8 px-4">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="flex items-center justify-center gap-3 mb-4">
            <Trophy className="w-10 h-10 text-yellow-400" />
            <h1 className="text-4xl font-bold text-white">Leaderboard</h1>
          </div>
          <p className="text-gray-400">
            Compete with other users and climb to the top!
          </p>
        </div>

        {/* Period Filter */}
        <div className="flex flex-wrap items-center justify-between gap-4 mb-6">
          <div className="flex flex-wrap gap-2">
            {periods.map((period) => (
              <button
                key={period.value}
                onClick={() => handlePeriodChange(period.value)}
                className={`
                  px-4 py-2 rounded-lg font-medium transition-all duration-300
                  flex items-center gap-2
                  ${selectedPeriod === period.value
                    ? 'bg-blue-600 text-white shadow-lg shadow-blue-500/50'
                    : 'bg-gray-800 text-gray-300 hover:bg-gray-700'
                  }
                `}
              >
                <span>{period.emoji}</span>
                <span>{period.label}</span>
              </button>
            ))}
          </div>

          <button
            onClick={handleRefresh}
            disabled={refreshing}
            className="px-4 py-2 bg-gray-800 text-white rounded-lg hover:bg-gray-700 transition-all duration-300 flex items-center gap-2 disabled:opacity-50"
          >
            <RefreshCw className={`w-4 h-4 ${refreshing ? 'animate-spin' : ''}`} />
            <span>Refresh</span>
          </button>
        </div>

        {/* User's Current Rank */}
        {user && userRank && (
          <UserRankCard rankData={userRank} user={user} />
        )}

        {/* Loading State */}
        {loading ? (
          <div className="flex justify-center items-center py-20">
            <div className="animate-spin rounded-full h-16 w-16 border-t-2 border-b-2 border-blue-500"></div>
          </div>
        ) : (
          <>
            {/* Leaderboard List */}
            {leaderboard.length > 0 ? (
              <div className="space-y-3">
                {leaderboard.map((userEntry) => (
                  <LeaderboardCard
                    key={userEntry.userId}
                    user={userEntry}
                    currentUserId={user?.uid}
                  />
                ))}
              </div>
            ) : (
              <div className="text-center py-20">
                <Trophy className="w-20 h-20 text-gray-600 mx-auto mb-4" />
                <h3 className="text-xl font-semibold text-gray-400 mb-2">
                  No Data Available
                </h3>
                <p className="text-gray-500">
                  Be the first to earn CNE and appear on the leaderboard!
                </p>
              </div>
            )}
          </>
        )}

        {/* Footer Info */}
        <div className="mt-8 text-center text-gray-500 text-sm">
          <p>Rankings are updated in real-time based on total earnings</p>
          <p className="mt-1">Keep earning CNE to climb the leaderboard! 🚀</p>
        </div>
      </div>
    </div>
  );
};

export default LeaderboardPage;
