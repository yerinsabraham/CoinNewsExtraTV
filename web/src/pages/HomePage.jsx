import { useAuth } from '../contexts/AuthContext';
import { useBalanceStore } from '../stores/balanceStore';

const HomePage = () => {
  const { user } = useAuth();
  const balance = useBalanceStore();

  return (
    <div className="min-h-screen bg-dark-bg p-6">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold mb-6">Welcome, {user?.displayName || 'User'}!</h1>
        
        <div className="bg-dark-card p-6 rounded-xl mb-6">
          <h2 className="text-xl font-semibold mb-2">Your CNE Balance</h2>
          <p className="text-4xl font-black text-primary">
            {balance.balance.toFixed(2)} CNE
          </p>
          <p className="text-dark-text mt-2">
            Total Earnings: {balance.totalEarnings.toFixed(2)} CNE
          </p>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-dark-card p-6 rounded-xl text-center">
            <div className="text-3xl mb-2">📺</div>
            <h3 className="font-semibold">Watch Videos</h3>
            <p className="text-sm text-dark-text">7 CNE per video</p>
          </div>

          <div className="bg-dark-card p-6 rounded-xl text-center">
            <div className="text-3xl mb-2">🎯</div>
            <h3 className="font-semibold">Quiz</h3>
            <p className="text-sm text-dark-text">2 CNE per answer</p>
          </div>

          <div className="bg-dark-card p-6 rounded-xl text-center">
            <div className="text-3xl mb-2">🎡</div>
            <h3 className="font-semibold">Spin2Earn</h3>
            <p className="text-sm text-dark-text">Win up to 1000 CNE</p>
          </div>

          <div className="bg-dark-card p-6 rounded-xl text-center">
            <div className="text-3xl mb-2">✅</div>
            <h3 className="font-semibold">Daily Check-in</h3>
            <p className="text-sm text-dark-text">28 CNE daily</p>
          </div>
        </div>

        <div className="mt-8 bg-primary/10 border border-primary p-4 rounded-lg">
          <p className="text-center">
            🎉 <strong>Phase 1 Complete!</strong> Authentication and basic layout are working.
            More features coming soon!
          </p>
        </div>
      </div>
    </div>
  );
};

export default HomePage;
