import React from 'react';
import { Clock, Coins, Flame } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

/**
 * CheckinHistory Component
 * Displays recent check-in history
 */
const CheckinHistory = ({ history = [] }) => {
  if (history.length === 0) {
    return (
      <div className="bg-dark-card rounded-lg p-6 text-center">
        <Clock className="w-12 h-12 text-gray-400 mx-auto mb-3" />
        <p className="text-gray-400">No check-in history yet</p>
        <p className="text-sm text-gray-500 mt-1">Your check-ins will appear here</p>
      </div>
    );
  }
  
  return (
    <div className="bg-dark-card rounded-lg p-6">
      <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
        <Clock className="w-5 h-5" />
        Recent Check-ins
      </h3>
      
      <div className="space-y-3 max-h-[400px] overflow-y-auto custom-scrollbar">
        {history.map((checkin) => (
          <div
            key={checkin.id}
            className="bg-dark-bg rounded-lg p-4 hover:bg-dark-bg/80 transition-colors"
          >
            <div className="flex items-center justify-between">
              {/* Date and Streak */}
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 bg-primary/20 rounded-full flex items-center justify-center">
                  {checkin.streak >= 7 ? (
                    <Flame className="w-6 h-6 text-orange-400" />
                  ) : (
                    <span className="text-xl font-bold text-primary">{checkin.streak}</span>
                  )}
                </div>
                <div>
                  <p className="text-white font-semibold">
                    Day {checkin.streak} Streak {checkin.streak >= 3 && '🔥'}
                  </p>
                  <p className="text-sm text-gray-400">
                    {checkin.timestamp 
                      ? formatDistanceToNow(checkin.timestamp, { addSuffix: true }) 
                      : 'Just now'}
                  </p>
                </div>
              </div>
              
              {/* Rewards */}
              <div className="text-right">
                <div className="flex items-center gap-1 text-green-400 font-bold mb-1">
                  <Coins className="w-4 h-4" />
                  <span>+{checkin.totalReward} CNE</span>
                </div>
                
                {checkin.bonusReward > 0 && (
                  <div className="text-xs space-y-0.5">
                    <p className="text-gray-400">
                      Base: {checkin.baseReward} CNE
                    </p>
                    <p className="text-purple-400">
                      Bonus: +{checkin.bonusReward} CNE
                    </p>
                  </div>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default CheckinHistory;
