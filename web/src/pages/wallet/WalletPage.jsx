import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { useBalanceStore } from '../../stores/balanceStore';
import { collection, query, orderBy, limit as firestoreLimit, getDocs } from 'firebase/firestore';
import { db } from '../../services/firebase';
import { ArrowLeft, Wallet as WalletIcon, TrendingUp, TrendingDown, History, Coins } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

/**
 * WalletPage - View balance and transaction history
 */
const WalletPage = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const balance = useBalanceStore();
  
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  
  useEffect(() => {
    if (user) {
      loadTransactions();
    }
  }, [user, filter]);
  
  const loadTransactions = async () => {
    try {
      setLoading(true);
      const transactionsRef = collection(db, 'users', user.uid, 'transactions');
      const q = query(
        transactionsRef,
        orderBy('timestamp', 'desc'),
        firestoreLimit(50)
      );
      
      const snapshot = await getDocs(q);
      const txs = [];
      
      snapshot.forEach((doc) => {
        const data = doc.data();
        txs.push({
          id: doc.id,
          ...data,
          timestamp: data.timestamp?.toDate()
        });
      });
      
      // Apply filter
      const filtered = filter === 'all' 
        ? txs 
        : txs.filter(tx => tx.type === filter);
      
      setTransactions(filtered);
    } catch (error) {
      console.error('Error loading transactions:', error);
    } finally {
      setLoading(false);
    }
  };
  
  const getTransactionIcon = (type) => {
    switch (type) {
      case 'watch2earn':
        return '📺';
      case 'quiz':
        return '🧠';
      case 'spin2earn':
        return '🎰';
      case 'daily_checkin':
        return '✅';
      case 'chat_message':
        return '💬';
      case 'referral_bonus':
        return '👥';
      case 'signup_bonus':
        return '🎁';
      default:
        return '💰';
    }
  };
  
  const filters = [
    { value: 'all', label: 'All' },
    { value: 'watch2earn', label: 'Videos' },
    { value: 'quiz', label: 'Quiz' },
    { value: 'spin2earn', label: 'Spin' },
    { value: 'daily_checkin', label: 'Check-in' },
    { value: 'chat_message', label: 'Chat' },
    { value: 'referral_bonus', label: 'Referrals' }
  ];
  
  if (loading) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin w-16 h-16 border-4 border-primary border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-gray-400">Loading wallet...</p>
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
          
          <div>
            <h1 className="text-3xl font-bold flex items-center gap-3">
              <WalletIcon className="w-8 h-8" />
              My Wallet
            </h1>
            <p className="text-white/90 mt-2">View your balance and transactions</p>
          </div>
        </div>
      </div>
      
      <div className="max-w-4xl mx-auto px-4 py-8">
        {/* Balance Card */}
        <div className="bg-gradient-to-br from-primary/20 to-green-600/20 border-2 border-primary rounded-xl p-8 mb-8">
          <div className="text-center">
            <p className="text-gray-300 mb-2">Total Balance</p>
            <p className="text-6xl font-bold text-white mb-4">
              {balance.balance.toFixed(2)} CNE
            </p>
            
            <div className="grid grid-cols-3 gap-4 mt-6">
              <div className="bg-dark-bg/50 rounded-lg p-4">
                <p className="text-sm text-gray-400 mb-1">Unlocked</p>
                <p className="text-xl font-bold text-green-400">
                  {balance.unlockedBalance.toFixed(2)}
                </p>
              </div>
              <div className="bg-dark-bg/50 rounded-lg p-4">
                <p className="text-sm text-gray-400 mb-1">Locked</p>
                <p className="text-xl font-bold text-orange-400">
                  {balance.lockedBalance.toFixed(2)}
                </p>
              </div>
              <div className="bg-dark-bg/50 rounded-lg p-4">
                <p className="text-sm text-gray-400 mb-1">Total Earned</p>
                <p className="text-xl font-bold text-primary">
                  {balance.totalEarnings.toFixed(2)}
                </p>
              </div>
            </div>
          </div>
        </div>
        
        {/* Filters */}
        <div className="mb-6 flex gap-2 overflow-x-auto pb-2">
          {filters.map((f) => (
            <button
              key={f.value}
              onClick={() => setFilter(f.value)}
              className={`
                px-4 py-2 rounded-lg font-semibold whitespace-nowrap transition-colors
                ${filter === f.value
                  ? 'bg-primary text-white'
                  : 'bg-dark-card text-gray-400 hover:bg-dark-card/80'
                }
              `}
            >
              {f.label}
            </button>
          ))}
        </div>
        
        {/* Transactions */}
        <div className="bg-dark-card rounded-lg p-6">
          <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
            <History className="w-5 h-5" />
            Transaction History
          </h3>
          
          {transactions.length === 0 ? (
            <div className="text-center py-12">
              <Coins className="w-16 h-16 text-gray-600 mx-auto mb-4" />
              <p className="text-gray-400 text-lg mb-2">No transactions yet</p>
              <p className="text-gray-500 text-sm">Start earning to see your transaction history</p>
            </div>
          ) : (
            <div className="space-y-3 max-h-[600px] overflow-y-auto custom-scrollbar">
              {transactions.map((tx) => (
                <div
                  key={tx.id}
                  className="bg-dark-bg rounded-lg p-4 hover:bg-dark-bg/80 transition-colors"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-12 h-12 rounded-full bg-primary/20 flex items-center justify-center text-2xl">
                        {getTransactionIcon(tx.type)}
                      </div>
                      <div>
                        <p className="font-semibold text-white">{tx.description}</p>
                        <p className="text-sm text-gray-400">
                          {tx.timestamp 
                            ? formatDistanceToNow(tx.timestamp, { addSuffix: true }) 
                            : 'Just now'}
                        </p>
                      </div>
                    </div>
                    
                    <div className="text-right">
                      <p className="text-green-400 font-bold text-lg flex items-center gap-1">
                        <TrendingUp className="w-4 h-4" />
                        +{tx.amount.toFixed(2)} CNE
                      </p>
                      <p className="text-xs text-gray-500">
                        Balance: {tx.newBalance?.toFixed(2) || '0.00'}
                      </p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default WalletPage;
