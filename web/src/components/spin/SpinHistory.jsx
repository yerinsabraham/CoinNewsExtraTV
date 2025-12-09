import React from 'react';
import { Clock, TrendingUp } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

/**
 * SpinHistory Component
 * Displays user's recent spin results
 */
const SpinHistory = ({ history = [] }) => {
  if (history.length === 0) {
    return (
      <div className="bg-dark-card rounded-lg p-6 text-center">
        <Clock className="w-12 h-12 text-gray-400 mx-auto mb-3" />
        <p className="text-gray-400">No spin history yet</p>
        <p className="text-sm text-gray-500 mt-1">Your recent spins will appear here</p>
      </div>
    );
  }
  
  return (
    <div className="bg-dark-card rounded-lg p-6">
      <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
        <Clock className="w-5 h-5" />
        Recent Spins
      </h3>
      
      <div className="space-y-3 max-h-[400px] overflow-y-auto custom-scrollbar">
        {history.map((spin) => (
          <div
            key={spin.id}
            className="bg-dark-bg rounded-lg p-4 flex items-center justify-between hover:bg-dark-bg/80 transition-colors"
          >
            {/* Reward Info */}
            <div className="flex items-center gap-3">
              <div
                className="w-12 h-12 rounded-full flex items-center justify-center font-bold text-white shadow-lg"
                style={{ backgroundColor: spin.color }}
              >
                {spin.reward}
              </div>
              <div>
                <p className="text-white font-semibold">{spin.rewardLabel}</p>
                <p className="text-sm text-gray-400">
                  {spin.timestamp ? formatDistanceToNow(spin.timestamp, { addSuffix: true }) : 'Just now'}
                </p>
              </div>
            </div>
            
            {/* Balance Change */}
            <div className="text-right">
              <p className="text-green-400 font-bold flex items-center gap-1">
                <TrendingUp className="w-4 h-4" />
                +{spin.reward} CNE
              </p>
              <p className="text-xs text-gray-500">
                {spin.oldBalance?.toLocaleString()} → {spin.newBalance?.toLocaleString()}
              </p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default SpinHistory;
