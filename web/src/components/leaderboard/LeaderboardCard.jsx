import React from 'react';
import { Trophy, TrendingUp } from 'lucide-react';
import { formatRank, getRankColorClass } from '../../services/leaderboard.service';

const LeaderboardCard = ({ user, currentUserId }) => {
  const isCurrentUser = user.userId === currentUserId;
  const avatarUrl = user.photoURL || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.displayName)}&background=random`;

  return (
    <div
      className={`
        bg-gray-800/50 backdrop-blur-sm rounded-xl p-4 
        hover:bg-gray-800 transition-all duration-300
        border-2 ${isCurrentUser ? 'border-blue-500' : 'border-gray-700'}
        ${user.rank <= 3 ? 'shadow-lg shadow-yellow-500/20' : ''}
      `}
    >
      <div className="flex items-center gap-4">
        {/* Rank */}
        <div className={`text-3xl font-bold ${getRankColorClass(user.rank)} min-w-[60px] text-center`}>
          {formatRank(user.rank)}
        </div>

        {/* Avatar */}
        <div className="relative">
          <img
            src={avatarUrl}
            alt={user.displayName}
            className={`w-14 h-14 rounded-full object-cover ${
              user.rank <= 3 ? 'ring-4 ring-yellow-400' : 'ring-2 ring-gray-600'
            }`}
          />
          {user.rank === 1 && (
            <div className="absolute -top-1 -right-1 bg-yellow-400 rounded-full p-1">
              <Trophy className="w-4 h-4 text-gray-900" />
            </div>
          )}
        </div>

        {/* User Info */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h3 className="font-semibold text-white truncate">
              {user.displayName}
              {isCurrentUser && (
                <span className="ml-2 text-xs bg-blue-500 px-2 py-1 rounded-full">You</span>
              )}
            </h3>
          </div>
          <div className="text-sm text-gray-400 flex items-center gap-4 mt-1">
            <span>📺 {user.videosWatched || 0} videos</span>
            <span>🧠 {user.quizzesCompleted || 0} quizzes</span>
            {user.checkInStreak > 0 && (
              <span>🔥 {user.checkInStreak} day streak</span>
            )}
          </div>
        </div>

        {/* Earnings */}
        <div className="text-right">
          <div className="flex items-center gap-2 justify-end">
            <TrendingUp className="w-5 h-5 text-green-400" />
            <span className="text-2xl font-bold text-yellow-400">
              {user.earnings.toLocaleString()}
            </span>
            <span className="text-gray-400">CNE</span>
          </div>
          <div className="text-xs text-gray-500 mt-1">
            Balance: {user.balance.toLocaleString()} CNE
          </div>
        </div>
      </div>
    </div>
  );
};

export default LeaderboardCard;
