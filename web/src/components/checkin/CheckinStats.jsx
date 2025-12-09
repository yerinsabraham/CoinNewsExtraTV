import React from 'react';
import { Flame, TrendingUp, Calendar, Trophy } from 'lucide-react';

/**
 * CheckinStats Component
 * Displays check-in statistics
 */
const CheckinStats = ({ stats = {}, nextMilestone = null }) => {
  const {
    currentStreak = 0,
    longestStreak = 0,
    totalCheckins = 0,
    totalEarned = 0,
    averageReward = 28
  } = stats;
  
  const statCards = [
    {
      icon: Flame,
      label: 'Current Streak',
      value: `${currentStreak} ${currentStreak === 1 ? 'day' : 'days'}`,
      color: 'text-orange-400',
      bgColor: 'bg-orange-500/10'
    },
    {
      icon: Trophy,
      label: 'Longest Streak',
      value: `${longestStreak} ${longestStreak === 1 ? 'day' : 'days'}`,
      color: 'text-yellow-400',
      bgColor: 'bg-yellow-500/10'
    },
    {
      icon: Calendar,
      label: 'Total Check-ins',
      value: totalCheckins.toLocaleString(),
      color: 'text-blue-400',
      bgColor: 'bg-blue-500/10'
    },
    {
      icon: TrendingUp,
      label: 'Total Earned',
      value: `${totalEarned.toLocaleString()} CNE`,
      color: 'text-green-400',
      bgColor: 'bg-green-500/10'
    }
  ];
  
  return (
    <div>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        {statCards.map((stat, index) => {
          const Icon = stat.icon;
          return (
            <div
              key={index}
              className="bg-dark-card rounded-lg p-4 hover:bg-dark-card/80 transition-colors"
            >
              <div className="flex items-center gap-3">
                <div className={`w-12 h-12 rounded-lg ${stat.bgColor} flex items-center justify-center`}>
                  <Icon className={`w-6 h-6 ${stat.color}`} />
                </div>
                <div>
                  <p className="text-sm text-gray-400">{stat.label}</p>
                  <p className={`text-xl font-bold ${stat.color}`}>{stat.value}</p>
                </div>
              </div>
            </div>
          );
        })}
      </div>
      
      {/* Next Milestone */}
      {nextMilestone && (
        <div className="bg-gradient-to-r from-purple-500/10 to-pink-500/10 border border-purple-500/30 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-400 mb-1">Next Streak Bonus</p>
              <p className="text-2xl font-bold text-white">
                {nextMilestone.days} Day Streak
              </p>
            </div>
            <div className="text-right">
              <p className="text-sm text-gray-400 mb-1">Bonus Reward</p>
              <p className="text-2xl font-bold text-green-400">
                +{nextMilestone.reward} CNE
              </p>
            </div>
          </div>
          <div className="mt-3">
            <div className="flex items-center justify-between text-sm mb-2">
              <span className="text-gray-400">Progress</span>
              <span className="text-white font-semibold">
                {currentStreak} / {nextMilestone.days} days
              </span>
            </div>
            <div className="w-full bg-dark-bg rounded-full h-3 overflow-hidden">
              <div
                className="bg-gradient-to-r from-purple-500 to-pink-500 h-full rounded-full transition-all duration-500"
                style={{ width: `${(currentStreak / nextMilestone.days) * 100}%` }}
              />
            </div>
            <p className="text-xs text-gray-400 mt-2 text-center">
              {nextMilestone.remaining} {nextMilestone.remaining === 1 ? 'day' : 'days'} until bonus!
            </p>
          </div>
        </div>
      )}
    </div>
  );
};

export default CheckinStats;
