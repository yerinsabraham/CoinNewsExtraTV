import React, { useState, useEffect } from 'react';
import { 
  UserPlus, Download, RefreshCw, Users, Database, CheckCircle
} from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { isAdmin } from '../../services/admin.service';
import { 
  getAdminCreatedAccounts,
  getAdminAccountsCount,
  getTotalUsersCount,
  exportAccountsAsCSV,
  exportAccountsAsTXT,
  downloadCSV,
  downloadTXT
} from '../../services/accountCreator.service';
import AccountGenerator from '../../components/admin/AccountGenerator';
import AccountsTable from '../../components/admin/AccountsTable';
import { toast } from 'react-hot-toast';

const AccountCreatorPage = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [accounts, setAccounts] = useState([]);
  const [stats, setStats] = useState({
    adminCreated: 0,
    totalUsers: 0
  });
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

    loadAccountsData();
  };

  const loadAccountsData = async () => {
    try {
      setLoading(true);
      const [accountsList, adminCount, totalCount] = await Promise.all([
        getAdminCreatedAccounts(),
        getAdminAccountsCount(),
        getTotalUsersCount()
      ]);

      setAccounts(accountsList);
      setStats({
        adminCreated: adminCount,
        totalUsers: totalCount
      });
    } catch (error) {
      console.error('Error loading accounts:', error);
      toast.error('Failed to load accounts data');
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadAccountsData();
    setRefreshing(false);
    toast.success('Data refreshed!');
  };

  const handleAccountCreated = (newAccount) => {
    loadAccountsData();
  };

  const handleExportCSV = () => {
    if (accounts.length === 0) {
      toast.error('No accounts to export');
      return;
    }

    const csvContent = exportAccountsAsCSV(accounts);
    downloadCSV(csvContent, `admin_accounts_${Date.now()}.csv`);
    toast.success('CSV file downloaded!');
  };

  const handleExportTXT = () => {
    if (accounts.length === 0) {
      toast.error('No accounts to export');
      return;
    }

    const txtContent = exportAccountsAsTXT(accounts);
    downloadTXT(txtContent, `admin_accounts_${Date.now()}.txt`);
    toast.success('TXT file downloaded!');
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-t-2 border-b-2 border-purple-500 mx-auto mb-4"></div>
          <p className="text-gray-400">Loading account creator...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 py-8 px-4">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="bg-gradient-to-r from-green-600 to-blue-600 rounded-2xl p-6 mb-8 shadow-xl">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="bg-white/20 p-3 rounded-xl">
                <UserPlus className="w-8 h-8 text-white" />
              </div>
              <div>
                <h1 className="text-3xl font-bold text-white">Account Creator</h1>
                <p className="text-green-100">Bulk account creation with Hedera wallets</p>
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

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <div className="bg-gradient-to-br from-blue-600 to-blue-700 rounded-xl p-6 shadow-xl">
            <div className="flex items-center justify-between mb-4">
              <div className="bg-white/20 p-3 rounded-lg">
                <UserPlus className="w-6 h-6 text-white" />
              </div>
              <CheckCircle className="w-5 h-5 text-blue-200" />
            </div>
            <div>
              <p className="text-blue-100 text-sm mb-1">Admin Created Accounts</p>
              <p className="text-4xl font-bold text-white">{stats.adminCreated.toLocaleString()}</p>
              <p className="text-blue-200 text-xs mt-2">Total accounts created via admin panel</p>
            </div>
          </div>

          <div className="bg-gradient-to-br from-purple-600 to-purple-700 rounded-xl p-6 shadow-xl">
            <div className="flex items-center justify-between mb-4">
              <div className="bg-white/20 p-3 rounded-lg">
                <Users className="w-6 h-6 text-white" />
              </div>
              <Database className="w-5 h-5 text-purple-200" />
            </div>
            <div>
              <p className="text-purple-100 text-sm mb-1">Total Platform Users</p>
              <p className="text-4xl font-bold text-white">{stats.totalUsers.toLocaleString()}</p>
              <p className="text-purple-200 text-xs mt-2">All registered users (normal + admin-created)</p>
            </div>
          </div>
        </div>

        {/* Account Generator */}
        <div className="mb-8">
          <AccountGenerator onAccountCreated={handleAccountCreated} />
        </div>

        {/* Accounts List */}
        <div className="bg-gray-800/50 rounded-xl p-6">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-xl font-bold text-white">Created Accounts</h3>
            <div className="flex gap-2">
              <button
                onClick={handleExportCSV}
                disabled={accounts.length === 0}
                className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Download className="w-4 h-4" />
                <span>Export CSV</span>
              </button>
              <button
                onClick={handleExportTXT}
                disabled={accounts.length === 0}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Download className="w-4 h-4" />
                <span>Export TXT</span>
              </button>
            </div>
          </div>

          <AccountsTable accounts={accounts} />
        </div>

        {/* Info Notice */}
        <div className="mt-8 bg-yellow-500/10 border border-yellow-500/30 rounded-xl p-4">
          <p className="text-yellow-500 font-medium mb-2">⚠️ Security Notice</p>
          <p className="text-gray-400 text-sm">
            Credentials are stored in plain text in Firestore for easy access. Ensure proper security measures are in place and restrict access to this admin panel.
            All created accounts receive a Hedera blockchain wallet and initial CNE balance.
          </p>
        </div>
      </div>
    </div>
  );
};

export default AccountCreatorPage;
