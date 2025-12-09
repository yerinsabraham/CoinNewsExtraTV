import React from 'react';
import { TrendingUp, TrendingDown } from 'lucide-react';
import { formatPrice, getChangeColor, getChangeBgColor } from '../../services/market.service';

/**
 * CoinCard Component
 * Displays a cryptocurrency price card
 */
const CoinCard = ({ coin, onClick }) => {
  const isPositive = coin.change24h >= 0;
  
  return (
    <button
      onClick={() => onClick && onClick(coin)}
      className="w-full bg-dark-card rounded-lg p-4 hover:bg-dark-card/80 transition-all hover:scale-[1.02] text-left"
    >
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center">
            <span className="text-lg font-bold text-primary">{coin.symbol}</span>
          </div>
          <div>
            <h3 className="font-bold text-white">{coin.symbol}</h3>
            <p className="text-xs text-gray-400">{coin.name}</p>
          </div>
        </div>
        
        <div className={`flex items-center gap-1 px-2 py-1 rounded-full text-sm font-semibold ${getChangeBgColor(coin.change24h)} ${getChangeColor(coin.change24h)}`}>
          {isPositive ? (
            <TrendingUp className="w-4 h-4" />
          ) : (
            <TrendingDown className="w-4 h-4" />
          )}
          <span>{Math.abs(coin.change24h).toFixed(2)}%</span>
        </div>
      </div>
      
      <div className="space-y-2">
        <div>
          <p className="text-2xl font-bold text-white">{formatPrice(coin.price)}</p>
        </div>
        
        <div className="flex items-center justify-between text-xs text-gray-400">
          <span>24h Vol: {formatLargeNumber(coin.volume24h)}</span>
          <span>MCap: {formatLargeNumber(coin.marketCap)}</span>
        </div>
      </div>
    </button>
  );
};

// Helper function for formatting large numbers (local copy)
function formatLargeNumber(num) {
  if (num >= 1e12) {
    return `$${(num / 1e12).toFixed(2)}T`;
  } else if (num >= 1e9) {
    return `$${(num / 1e9).toFixed(2)}B`;
  } else if (num >= 1e6) {
    return `$${(num / 1e6).toFixed(2)}M`;
  } else if (num >= 1e3) {
    return `$${(num / 1e3).toFixed(2)}K`;
  } else {
    return `$${num.toFixed(2)}`;
  }
}

export default CoinCard;
