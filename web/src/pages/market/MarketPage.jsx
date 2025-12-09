import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { fetchCoinPrices } from '../../services/market.service';
import CoinCard from '../../components/market/CoinCard';
import { ArrowLeft, TrendingUp, RefreshCw, Info } from 'lucide-react';
import toast from 'react-hot-toast';

/**
 * MarketPage - Cryptocurrency Market Data
 * Display real-time crypto prices from CoinGecko
 */
const MarketPage = () => {
  const navigate = useNavigate();
  
  const [coins, setCoins] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [lastUpdate, setLastUpdate] = useState(null);
  
  useEffect(() => {
    loadMarketData();
    
    // Auto-refresh every 60 seconds
    const interval = setInterval(() => {
      loadMarketData(true);
    }, 60000);
    
    return () => clearInterval(interval);
  }, []);
  
  const loadMarketData = async (silent = false) => {
    try {
      if (!silent) setLoading(true);
      setRefreshing(true);
      
      const data = await fetchCoinPrices();
      setCoins(data);
      setLastUpdate(new Date());
      
      if (silent) {
        toast.success('Market data updated', { duration: 2000 });
      }
    } catch (error) {
      console.error('Error loading market data:', error);
      toast.error('Failed to load market data');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };
  
  const handleRefresh = () => {
    loadMarketData(true);
  };
  
  if (loading) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin w-16 h-16 border-4 border-primary border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-gray-400">Loading market data...</p>
        </div>
      </div>
    );
  }
  
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
                <TrendingUp className="w-8 h-8" />
                Market Data
              </h1>
              <p className="text-white/90 mt-2">
                Real-time cryptocurrency prices
              </p>
            </div>
            
            <button
              onClick={handleRefresh}
              disabled={refreshing}
              className="flex items-center gap-2 bg-white/20 hover:bg-white/30 px-4 py-2 rounded-lg transition-colors disabled:opacity-50"
            >
              <RefreshCw className={`w-5 h-5 ${refreshing ? 'animate-spin' : ''}`} />
              <span>Refresh</span>
            </button>
          </div>
        </div>
      </div>
      
      <div className="max-w-7xl mx-auto px-4 py-8">
        {/* Info Banner */}
        <div className="bg-blue-500/10 border border-blue-500/30 rounded-lg p-4 mb-8 flex items-start gap-3">
          <Info className="w-5 h-5 text-blue-400 flex-shrink-0 mt-0.5" />
          <div className="text-sm text-gray-300">
            <p className="font-semibold text-white mb-1">Market Data Info:</p>
            <ul className="list-disc list-inside space-y-1 text-gray-400">
              <li>Live prices from CoinGecko API</li>
              <li>Auto-updates every 60 seconds</li>
              <li>24-hour price changes and trading volumes</li>
              <li>Click on any coin for more details (coming soon)</li>
            </ul>
          </div>
        </div>
        
        {/* Last Update Time */}
        {lastUpdate && (
          <div className="text-center mb-6">
            <p className="text-sm text-gray-400">
              Last updated: {lastUpdate.toLocaleTimeString()}
            </p>
          </div>
        )}
        
        {/* Coins Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {coins.map((coin) => (
            <CoinCard
              key={coin.id}
              coin={coin}
              onClick={() => toast('Detailed view coming soon!', { icon: '📊' })}
            />
          ))}
        </div>
        
        {/* Powered By */}
        <div className="text-center mt-8 text-sm text-gray-500">
          Powered by <a href="https://www.coingecko.com" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">CoinGecko API</a>
        </div>
      </div>
    </div>
  );
};

export default MarketPage;
