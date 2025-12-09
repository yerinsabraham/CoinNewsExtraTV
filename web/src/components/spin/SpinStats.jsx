import React from 'react';
import { BarChart3, Coins, TrendingUp, Trophy } from 'lucide-react';

/**
 * SpinStats Component
 * Displays spin statistics
 */
const SpinStats = ({ stats = {} }) => {
  const {
    totalSpins = 0,
    totalEarned = 0,
    averageReward = 0,
    highestReward = 0
  } = stats;
  
  const statCards = [
    {
      icon: BarChart3,
      label: 'Total Spins',
      value: totalSpins.toLocaleString(),
      color: 'text-blue-400',
      bgColor: 'bg-blue-500/10'
    },
    {
      icon: Coins,
      label: 'Total Earned',
      value: `${totalEarned.toLocaleString()} CNE`,
      color: 'text-green-400',
      bgColor: 'bg-green-500/10'
    },
    {
      icon: TrendingUp,
      label: 'Average Win',
      value: `${averageReward.toLocaleString()} CNE`,
      color: 'text-yellow-400',
      bgColor: 'bg-yellow-500/10'
    },
    {
      icon: Trophy,
      label: 'Highest Win',
      value: `${highestReward.toLocaleString()} CNE`,
      color: 'text-purple-400',
      bgColor: 'bg-purple-500/10'
    }
  ];
  
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
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
  );
};

export default SpinStats;
