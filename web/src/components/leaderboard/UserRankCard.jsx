import React from 'react';
import { Award, Users } from 'lucide-react';
import { formatRank, getRankColorClass } from '../../services/leaderboard.service';

const UserRankCard = ({ rankData, user }) => {
  if (!rankData || !rankData.rank) {
    return (
      <div className="bg-gradient-to-r from-gray-800 to-gray-700 rounded-2xl p-6 mb-6">
        <div className="text-center">
          <Users className="w-12 h-12 text-gray-400 mx-auto mb-3" />
          <p className="text-gray-400">Start earning to appear on the leaderboard!</p>
        </div>
      </div>
    );
  }

  const avatarUrl = user?.photoURL || `https://ui-avatars.com/api/?name=${encodeURIComponent(user?.displayName || 'User')}&background=random`;

  return (
    <div className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-2xl p-6 mb-6 shadow-xl">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <img
            src={avatarUrl}
            alt={user?.displayName}
            className="w-16 h-16 rounded-full ring-4 ring-white/30"
          />
          <div>
            <h3 className="text-white font-semibold text-lg">{user?.displayName || 'You'}</h3>
            <p className="text-blue-100 text-sm">Your Current Rank</p>
          </div>
        </div>

        <div className="text-right">
          <div className="flex items-center gap-2 justify-end mb-1">
            <Award className="w-6 h-6 text-yellow-300" />
            <span className={`text-4xl font-bold ${getRankColorClass(rankData.rank)}`}>
              {formatRank(rankData.rank)}
            </span>
          </div>
          <p className="text-blue-100 text-sm">
            out of {rankData.totalUsers.toLocaleString()} users
          </p>
        </div>
      </div>

      <div className="mt-4 pt-4 border-t border-white/20">
        <div className="flex justify-between items-center">
          <span className="text-blue-100">Total Earnings:</span>
          <span className="text-2xl font-bold text-yellow-300">
            {rankData.earnings.toLocaleString()} CNE
          </span>
        </div>
      </div>
    </div>
  );
};

export default UserRankCard;
