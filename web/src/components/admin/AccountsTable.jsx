import React from 'react';
import { Copy, Download, Eye, EyeOff } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { copyToClipboard } from '../../services/accountCreator.service';
import { toast } from 'react-hot-toast';

const AccountsTable = ({ accounts }) => {
  const [showPasswords, setShowPasswords] = React.useState({});

  const handleCopy = async (text, label) => {
    const success = await copyToClipboard(text);
    if (success) {
      toast.success(`${label} copied!`);
    } else {
      toast.error('Failed to copy');
    }
  };

  const togglePasswordVisibility = (accountId) => {
    setShowPasswords(prev => ({
      ...prev,
      [accountId]: !prev[accountId]
    }));
  };

  const maskPassword = (password) => {
    return '•'.repeat(password.length);
  };

  if (!accounts || accounts.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-400">No accounts created yet. Use the generator above to create your first account.</p>
      </div>
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full">
        <thead>
          <tr className="border-b border-gray-700">
            <th className="text-left py-3 px-4 text-gray-400 font-medium">#</th>
            <th className="text-left py-3 px-4 text-gray-400 font-medium">Email</th>
            <th className="text-left py-3 px-4 text-gray-400 font-medium">Password</th>
            <th className="text-left py-3 px-4 text-gray-400 font-medium">Hedera Account</th>
            <th className="text-right py-3 px-4 text-gray-400 font-medium">CNE Balance</th>
            <th className="text-left py-3 px-4 text-gray-400 font-medium">Status</th>
            <th className="text-left py-3 px-4 text-gray-400 font-medium">Created</th>
            <th className="text-right py-3 px-4 text-gray-400 font-medium">Actions</th>
          </tr>
        </thead>
        <tbody>
          {accounts.map((account, index) => (
            <tr key={account.id} className="border-b border-gray-800 hover:bg-gray-800/50 transition-colors">
              <td className="py-3 px-4 text-gray-400">{index + 1}</td>
              
              {/* Email */}
              <td className="py-3 px-4">
                <div className="flex items-center gap-2">
                  <span className="text-white font-mono text-sm">{account.email}</span>
                  <button
                    onClick={() => handleCopy(account.email, 'Email')}
                    className="text-gray-400 hover:text-blue-400 transition-colors"
                  >
                    <Copy className="w-3 h-3" />
                  </button>
                </div>
              </td>

              {/* Password */}
              <td className="py-3 px-4">
                <div className="flex items-center gap-2">
                  <span className="text-white font-mono text-sm">
                    {showPasswords[account.id] ? account.password : maskPassword(account.password)}
                  </span>
                  <button
                    onClick={() => togglePasswordVisibility(account.id)}
                    className="text-gray-400 hover:text-yellow-400 transition-colors"
                  >
                    {showPasswords[account.id] ? <EyeOff className="w-3 h-3" /> : <Eye className="w-3 h-3" />}
                  </button>
                  <button
                    onClick={() => handleCopy(account.password, 'Password')}
                    className="text-gray-400 hover:text-blue-400 transition-colors"
                  >
                    <Copy className="w-3 h-3" />
                  </button>
                </div>
              </td>

              {/* Hedera Account */}
              <td className="py-3 px-4">
                {account.hederaAccountId ? (
                  <div className="flex items-center gap-2">
                    <span className="text-green-400 font-mono text-sm">{account.hederaAccountId}</span>
                    <button
                      onClick={() => handleCopy(account.hederaAccountId, 'Hedera Account')}
                      className="text-gray-400 hover:text-green-400 transition-colors"
                    >
                      <Copy className="w-3 h-3" />
                    </button>
                  </div>
                ) : (
                  <span className="text-gray-500 text-sm">N/A</span>
                )}
              </td>

              {/* Balance */}
              <td className="py-3 px-4 text-right">
                <span className="text-yellow-400 font-semibold">{account.cneBalance || 0}</span>
                <span className="text-gray-500 ml-1 text-sm">CNE</span>
              </td>

              {/* Status */}
              <td className="py-3 px-4">
                {account.status === 'active' ? (
                  <span className="text-xs bg-green-500/20 text-green-400 px-2 py-1 rounded">Active</span>
                ) : account.status === 'pending_hedera' ? (
                  <span className="text-xs bg-yellow-500/20 text-yellow-400 px-2 py-1 rounded">Pending</span>
                ) : (
                  <span className="text-xs bg-gray-500/20 text-gray-400 px-2 py-1 rounded">{account.status}</span>
                )}
              </td>

              {/* Created Date */}
              <td className="py-3 px-4 text-gray-400 text-sm">
                {account.createdAt ? formatDistanceToNow(account.createdAt, { addSuffix: true }) : 'N/A'}
              </td>

              {/* Actions */}
              <td className="py-3 px-4 text-right">
                <button
                  onClick={() => handleCopy(
                    `Email: ${account.email}\nPassword: ${account.password}\nHedera: ${account.hederaAccountId || 'N/A'}`,
                    'Full credentials'
                  )}
                  className="text-blue-400 hover:text-blue-300 transition-colors"
                  title="Copy all credentials"
                >
                  <Download className="w-4 h-4" />
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default AccountsTable;
