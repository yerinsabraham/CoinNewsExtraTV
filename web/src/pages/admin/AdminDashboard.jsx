import React, { useState, useEffect } from 'react';
import { 
  Shield, Users, Video, Brain, DollarSign, Activity, 
  TrendingUp, RefreshCw, AlertCircle 
} from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { 
  isAdmin, 
  getPlatformStats, 
  getAllUsers, 
  toggleUserBan, 
  updateUserBalance,
  getSystemAnalytics
} from '../../services/admin.service';
import StatsCard from '../../components/admin/StatsCard';
import UserManagementTable from '../../components/admin/UserManagementTable';
import { toast } from 'react-hot-toast';

const AdminDashboard = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState(null);
  const [analytics, setAnalytics] = useState(null);
  const [users, setUsers] = useState([]);
  const [activeTab, setActiveTab] = useState('overview');
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    checkAdminAccess();
  }, [user]);

  const checkAdminAccess = async () => {
    if (!user) {
      navigate('/');
      return;
    }

    const adminStatus = await isAdmin(user.uid, user.email);
    if (!adminStatus) {
      toast.error('Access denied: Admin privileges required');
      navigate('/');
      return;
    }

    loadDashboardData();
  };

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const [platformStats, systemAnalytics, usersList] = await Promise.all([
        getPlatformStats(),
        getSystemAnalytics(),
        getAllUsers(50)
      ]);

      setStats(platformStats);
      setAnalytics(systemAnalytics);
      setUsers(usersList);
    } catch (error) {
      console.error('Error loading dashboard:', error);
      toast.error('Failed to load dashboard data');
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadDashboardData();
    setRefreshing(false);
    toast.success('Dashboard refreshed!');
  };

  const handleBanUser = async (selectedUser) => {
    const action = selectedUser.banned ? 'unban' : 'ban';
    const reason = selectedUser.banned ? '' : prompt('Enter ban reason:');
    
    if (!selectedUser.banned && !reason) return;

    try {
      await toggleUserBan(selectedUser.id, !selectedUser.banned, reason);
      toast.success(`User ${action}ned successfully`);
      loadDashboardData();
    } catch (error) {
      toast.error(`Failed to ${action} user`);
    }
  };

  const handleEditBalance = async (selectedUser) => {
    const newBalance = prompt(`Enter new balance for ${selectedUser.displayName}:`, selectedUser.balance);
    if (!newBalance) return;

    const balance = parseFloat(newBalance);
    if (isNaN(balance) || balance < 0) {
      toast.error('Invalid balance amount');
      return;
    }

    try {
      await updateUserBalance(selectedUser.id, balance, 'Admin manual adjustment');
      toast.success('Balance updated successfully');
      loadDashboardData();
    } catch (error) {
      toast.error('Failed to update balance');
    }
  };

  const handleDeleteUser = async (selectedUser) => {
    if (!window.confirm(`Are you sure you want to delete ${selectedUser.displayName}? This action cannot be undone.`)) {
      return;
    }

    toast.error('Delete user functionality requires additional security implementation');
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-t-2 border-b-2 border-purple-500 mx-auto mb-4"></div>
          <p className="text-gray-400">Loading admin dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 py-8 px-4">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="bg-gradient-to-r from-purple-600 to-blue-600 rounded-2xl p-6 mb-8 shadow-xl">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="bg-white/20 p-3 rounded-xl">
                <Shield className="w-8 h-8 text-white" />
              </div>
              <div>
                <h1 className="text-3xl font-bold text-white">Admin Dashboard</h1>
                <p className="text-blue-100">Platform Management & Analytics</p>
              </div>
            </div>
            
            <button
              onClick={handleRefresh}
              disabled={refreshing}
              className="bg-white/20 hover:bg-white/30 text-white px-4 py-2 rounded-lg transition-all duration-200 flex items-center gap-2"
            >
              <RefreshCw className={`w-4 h-4 ${refreshing ? 'animate-spin' : ''}`} />
              <span>Refresh</span>
            </button>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex gap-2 mb-6 overflow-x-auto">
          {[
            { id: 'overview', label: 'Overview', icon: Activity },
            { id: 'users', label: 'Users', icon: Users },
            { id: 'analytics', label: 'Analytics', icon: TrendingUp }
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`
                px-6 py-3 rounded-lg font-medium transition-all duration-300 flex items-center gap-2 whitespace-nowrap
                ${activeTab === tab.id
                  ? 'bg-purple-600 text-white shadow-lg shadow-purple-500/50'
                  : 'bg-gray-800 text-gray-300 hover:bg-gray-700'
                }
              `}
            >
              <tab.icon className="w-5 h-5" />
              <span>{tab.label}</span>
            </button>
          ))}
        </div>

        {/* Overview Tab */}
        {activeTab === 'overview' && stats && (
          <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <StatsCard
                icon={Users}
                label="Total Users"
                value={stats.totalUsers.toLocaleString()}
                subtitle={`${stats.activeUsers} active today`}
                color="blue"
              />
              <StatsCard
                icon={DollarSign}
                label="CNE Distributed"
                value={stats.totalCNEDistributed.toLocaleString()}
                subtitle="All-time earnings"
                color="green"
              />
              <StatsCard
                icon={Activity}
                label="CNE Balance"
                value={stats.totalCNEBalance.toLocaleString()}
                subtitle="Current user balances"
                color="purple"
              />
              <StatsCard
                icon={Video}
                label="Total Videos"
                value={stats.totalVideos.toLocaleString()}
                subtitle="Available to watch"
                color="orange"
              />
              <StatsCard
                icon={Brain}
                label="Total Quizzes"
                value={stats.totalQuizzes.toLocaleString()}
                subtitle="Active quizzes"
                color="pink"
              />
              <StatsCard
                icon={TrendingUp}
                label="Transactions"
                value={stats.totalTransactions.toLocaleString()}
                subtitle="All-time transactions"
                color="yellow"
              />
            </div>

            {/* Quick Actions */}
            <div className="bg-gray-800/50 rounded-xl p-6">
              <h3 className="text-xl font-bold text-white mb-4">Quick Actions</h3>
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <button
                  onClick={() => navigate('/admin/accounts')}
                  className="bg-gradient-to-r from-green-600 to-blue-600 hover:from-green-700 hover:to-blue-700 text-white px-4 py-3 rounded-lg transition-colors font-semibold"
                >
                  🎯 Create Accounts
                </button>
                <button className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-3 rounded-lg transition-colors">
                  Add New Video
                </button>
                <button className="bg-purple-600 hover:bg-purple-700 text-white px-4 py-3 rounded-lg transition-colors">
                  Create Quiz
                </button>
                <button className="bg-green-600 hover:bg-green-700 text-white px-4 py-3 rounded-lg transition-colors">
                  Send Notification
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Users Tab */}
        {activeTab === 'users' && (
          <div className="bg-gray-800/50 rounded-xl p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-bold text-white">User Management</h3>
              <span className="text-gray-400">{users.length} users</span>
            </div>
            
            <UserManagementTable
              users={users}
              onBanUser={handleBanUser}
              onEditBalance={handleEditBalance}
              onDeleteUser={handleDeleteUser}
            />
          </div>
        )}

        {/* Analytics Tab */}
        {activeTab === 'analytics' && analytics && (
          <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="bg-gray-800/50 rounded-xl p-6">
                <h3 className="text-lg font-bold text-white mb-4">CNE Distribution (7 Days)</h3>
                <p className="text-4xl font-bold text-green-400 mb-2">
                  {analytics.cneDistributed7Days.toLocaleString()}
                </p>
                <p className="text-gray-400">{analytics.transactionCount7Days} transactions</p>
              </div>

              <div className="bg-gray-800/50 rounded-xl p-6">
                <h3 className="text-lg font-bold text-white mb-4">CNE Distribution (30 Days)</h3>
                <p className="text-4xl font-bold text-blue-400 mb-2">
                  {analytics.cneDistributed30Days.toLocaleString()}
                </p>
                <p className="text-gray-400">{analytics.transactionCount30Days} transactions</p>
              </div>
            </div>

            <div className="bg-gray-800/50 rounded-xl p-6">
              <h3 className="text-lg font-bold text-white mb-4">Earnings by Type</h3>
              <div className="space-y-3">
                {Object.entries(analytics.typeBreakdown).map(([type, amount]) => (
                  <div key={type} className="flex items-center justify-between">
                    <span className="text-gray-300 capitalize">{type.replace('_', ' ')}</span>
                    <span className="text-yellow-400 font-semibold">{amount.toLocaleString()} CNE</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Warning Notice */}
        <div className="mt-8 bg-yellow-500/10 border border-yellow-500/30 rounded-xl p-4 flex items-start gap-3">
          <AlertCircle className="w-5 h-5 text-yellow-500 flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-yellow-500 font-medium">Admin Access Notice</p>
            <p className="text-gray-400 text-sm mt-1">
              You have full access to platform data. Please use admin privileges responsibly and in accordance with platform policies.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminDashboard;
