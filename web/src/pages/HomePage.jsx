import { useAuth } from '../contexts/AuthContext';
import { useBalanceStore } from '../stores/balanceStore';
import { useNavigate } from 'react-router-dom';
import { Video, Brain, Disc, CheckSquare, MessageSquare, Award, TrendingUp, BarChart3, Users, Wallet, User } from 'lucide-react';

const HomePage = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const balance = useBalanceStore();

  const features = [
    {
      icon: Video,
      title: 'Watch Videos',
      description: '7 CNE per video',
      color: 'text-red-500',
      bgColor: 'bg-red-500/20',
      route: '/videos',
      available: true
    },
    {
      icon: Brain,
      title: 'Quiz',
      description: '2 CNE per answer',
      color: 'text-blue-500',
      bgColor: 'bg-blue-500/20',
      route: '/quiz',
      available: true
    },
    {
      icon: Disc,
      title: 'Spin2Earn',
      description: 'Win up to 1000 CNE',
      color: 'text-purple-500',
      bgColor: 'bg-purple-500/20',
      route: '/spin',
      available: true
    },
    {
      icon: CheckSquare,
      title: 'Daily Check-in',
      description: '28 CNE daily',
      color: 'text-green-500',
      bgColor: 'bg-green-500/20',
      route: '/checkin',
      available: true
    },
    {
      icon: MessageSquare,
      title: 'Chat',
      description: '0.1 CNE per message',
      color: 'text-cyan-500',
      bgColor: 'bg-cyan-500/20',
      route: '/chat',
      available: true
    },
    {
      icon: BarChart3,
      title: 'Market Data',
      description: 'Live crypto prices',
      color: 'text-orange-500',
      bgColor: 'bg-orange-500/20',
      route: '/market',
      available: true
    },
    {
      icon: Users,
      title: 'Referrals',
      description: '100 CNE per referral',
      color: 'text-pink-500',
      bgColor: 'bg-pink-500/20',
      route: '/referral',
      available: true
    },
    {
      icon: Wallet,
      title: 'Wallet',
      description: 'View transactions',
      color: 'text-yellow-500',
      bgColor: 'bg-yellow-500/20',
      route: '/wallet',
      available: true
    },
    {
      icon: User,
      title: 'Profile',
      description: 'Manage account',
      color: 'text-indigo-500',
      bgColor: 'bg-indigo-500/20',
      route: '/profile',
      available: true
    }
  ];

  const handleFeatureClick = (feature) => {
    if (feature.available) {
      navigate(feature.route);
    }
  };

  return (
    <div className="min-h-screen bg-dark-bg text-white">
      {/* Header */}
      <div className="bg-gradient-to-r from-primary to-primary-light p-6">
        <div className="max-w-7xl mx-auto">
          <h1 className="text-3xl font-bold mb-2">
            Welcome back, {user?.displayName || 'User'}! 👋
          </h1>
          <p className="text-gray-200">Start earning CNE today!</p>
        </div>
      </div>

      <div className="max-w-7xl mx-auto p-6">
        {/* Balance Card */}
        <div className="bg-gradient-to-br from-dark-card to-dark-bg border border-dark-border rounded-xl p-6 mb-8 shadow-lg">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold text-gray-400">Your Balance</h2>
            <Award className="w-6 h-6 text-accent-gold" />
          </div>
          <p className="text-5xl font-black text-transparent bg-clip-text bg-gradient-to-r from-primary to-primary-light mb-2">
            {balance.balance.toFixed(2)} CNE
          </p>
          <div className="flex items-center gap-2 text-sm text-gray-400">
            <TrendingUp className="w-4 h-4" />
            <span>Total Earnings: {balance.totalEarnings.toFixed(2)} CNE</span>
          </div>
        </div>

        {/* Features Grid */}
        <div className="mb-8">
          <h2 className="text-2xl font-bold mb-4">Earn CNE</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {features.map((feature, index) => {
              const Icon = feature.icon;
              return (
                <button
                  key={index}
                  onClick={() => handleFeatureClick(feature)}
                  disabled={!feature.available}
                  className={`bg-dark-card border border-dark-border rounded-xl p-6 text-left transition-all duration-300 ${
                    feature.available
                      ? 'hover:scale-105 hover:shadow-xl cursor-pointer hover:border-primary'
                      : 'opacity-50 cursor-not-allowed'
                  }`}
                >
                  <div className={`${feature.bgColor} ${feature.color} w-12 h-12 rounded-lg flex items-center justify-center mb-4`}>
                    <Icon className="w-6 h-6" />
                  </div>
                  <h3 className="font-bold text-lg mb-1">{feature.title}</h3>
                  <p className="text-sm text-gray-400">{feature.description}</p>
                  {!feature.available && (
                    <span className="inline-block mt-2 text-xs bg-yellow-500/20 text-yellow-500 px-2 py-1 rounded">
                      Coming Soon
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        </div>

        {/* Status Banner */}
        <div className="bg-gradient-to-r from-primary to-primary-light rounded-lg p-6">
          <div className="flex items-start gap-4">
            <Video className="w-8 h-8 text-white flex-shrink-0" />
            <div>
              <h3 className="text-xl font-bold text-white mb-2">
                🎉 Watch2Earn is Now Live!
              </h3>
              <p className="text-white text-sm mb-3">
                Start watching crypto videos and earn 7 CNE per video. Watch at least 80% to get your reward!
              </p>
              <button
                onClick={() => navigate('/videos')}
                className="bg-white text-primary px-6 py-2 rounded-lg font-bold hover:bg-gray-100 transition-colors"
              >
                Start Watching
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default HomePage;
