import React, { useState } from 'react';
import { UserPlus, RefreshCw, Copy, CheckCircle, Users } from 'lucide-react';
import { 
  generateRandomEmail, 
  generateRandomPassword, 
  createBulkAccount,
  createBulkAccountsBatch,
  copyToClipboard
} from '../../services/accountCreator.service';
import { toast } from 'react-hot-toast';

const AccountGenerator = ({ onAccountCreated }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [creating, setCreating] = useState(false);
  const [lastCreatedAccount, setLastCreatedAccount] = useState(null);
  
  // Batch creation state
  const [batchCount, setBatchCount] = useState(10);
  const [batchCreating, setBatchCreating] = useState(false);
  const [batchProgress, setBatchProgress] = useState({ current: 0, total: 0 });
  const [batchResults, setBatchResults] = useState(null);

  const handleGenerateCredentials = () => {
    setEmail(generateRandomEmail());
    setPassword(generateRandomPassword());
  };

  const handleCreateAccount = async () => {
    if (!email || !password) {
      toast.error('Please generate credentials first');
      return;
    }

    try {
      setCreating(true);
      const result = await createBulkAccount(email, password);
      
      if (result.success) {
        setLastCreatedAccount(result);
        toast.success('Account created successfully!');
        
        // Callback to refresh the accounts list
        if (onAccountCreated) {
          onAccountCreated(result);
        }
        
        // Clear form
        setEmail('');
        setPassword('');
      }
    } catch (error) {
      console.error('Error creating account:', error);
      
      if (error.code === 'auth/email-already-in-use') {
        toast.error('Email already in use. Generate new credentials.');
      } else {
        toast.error('Failed to create account: ' + error.message);
      }
    } finally {
      setCreating(false);
    }
  };

  const handleCopy = async (text, label) => {
    const success = await copyToClipboard(text);
    if (success) {
      toast.success(`${label} copied to clipboard!`);
    } else {
      toast.error('Failed to copy to clipboard');
    }
  };

  const handleBatchCreate = async () => {
    if (batchCount < 1 || batchCount > 100) {
      toast.error('Please enter a valid number between 1 and 100');
      return;
    }

    const confirmMessage = `Are you sure you want to create ${batchCount} accounts?\n\nEstimated time: ~${Math.ceil(batchCount * 3)} seconds\n\nYou should verify these accounts in Firebase after creation.`;
    
    if (!window.confirm(confirmMessage)) {
      return;
    }

    try {
      setBatchCreating(true);
      setBatchProgress({ current: 0, total: batchCount });
      setBatchResults(null);
      
      toast.success(`Starting batch creation of ${batchCount} accounts...`);

      const results = await createBulkAccountsBatch(
        batchCount,
        // Progress callback
        (current, total, account) => {
          setBatchProgress({ current, total });
          if (account && account.success) {
            toast.success(`Account ${current}/${total} created: ${account.email}`, {
              duration: 2000
            });
          }
        },
        // Error callback
        (email, error) => {
          toast.error(`Failed to create ${email}: ${error}`, {
            duration: 3000
          });
        }
      );

      setBatchResults(results);
      
      if (results.successful.length > 0) {
        toast.success(`✅ Successfully created ${results.successful.length} accounts!`, {
          duration: 5000
        });
        
        // Refresh the accounts list
        if (onAccountCreated) {
          onAccountCreated();
        }
      }

      if (results.failed.length > 0) {
        toast.error(`❌ ${results.failed.length} accounts failed to create`, {
          duration: 5000
        });
      }

    } catch (error) {
      console.error('Batch creation error:', error);
      toast.error('Batch creation failed: ' + error.message);
    } finally {
      setBatchCreating(false);
      setBatchProgress({ current: 0, total: 0 });
    }
  };

  return (
    <div className="space-y-6">
      {/* Generator Section */}
      <div className="bg-gray-800/50 rounded-xl p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-bold text-white flex items-center gap-2">
            <UserPlus className="w-5 h-5 text-blue-400" />
            Generate New Account
          </h3>
          <button
            onClick={handleGenerateCredentials}
            disabled={creating}
            className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition-colors flex items-center gap-2 disabled:opacity-50"
          >
            <RefreshCw className="w-4 h-4" />
            Generate Credentials
          </button>
        </div>

        <div className="space-y-4">
          {/* Email Field */}
          <div>
            <label className="block text-sm text-gray-400 mb-2">Email</label>
            <div className="flex gap-2">
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Click 'Generate Credentials' to create email"
                className="flex-1 bg-gray-900 text-white px-4 py-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                readOnly
              />
              {email && (
                <button
                  onClick={() => handleCopy(email, 'Email')}
                  className="px-4 py-3 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors"
                >
                  <Copy className="w-4 h-4" />
                </button>
              )}
            </div>
          </div>

          {/* Password Field */}
          <div>
            <label className="block text-sm text-gray-400 mb-2">Password</label>
            <div className="flex gap-2">
              <input
                type="text"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Click 'Generate Credentials' to create password"
                className="flex-1 bg-gray-900 text-white px-4 py-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 font-mono"
                readOnly
              />
              {password && (
                <button
                  onClick={() => handleCopy(password, 'Password')}
                  className="px-4 py-3 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors"
                >
                  <Copy className="w-4 h-4" />
                </button>
              )}
            </div>
          </div>

          {/* Create Button */}
          <button
            onClick={handleCreateAccount}
            disabled={!email || !password || creating}
            className="w-full py-4 bg-gradient-to-r from-green-600 to-blue-600 hover:from-green-700 hover:to-blue-700 text-white rounded-lg font-semibold transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            {creating ? (
              <>
                <RefreshCw className="w-5 h-5 animate-spin" />
                Creating Account & Hedera Wallet...
              </>
            ) : (
              <>
                <UserPlus className="w-5 h-5" />
                Create Account
              </>
            )}
          </button>
        </div>
      </div>

      {/* Last Created Account Display */}
      {lastCreatedAccount && (
        <div className="bg-green-600/20 border border-green-500/50 rounded-xl p-6">
          <div className="flex items-center gap-2 mb-4">
            <CheckCircle className="w-5 h-5 text-green-400" />
            <h4 className="text-lg font-bold text-green-400">Account Created Successfully!</h4>
          </div>
          
          <div className="space-y-3 text-sm">
            <div className="flex justify-between items-center">
              <span className="text-gray-400">Email:</span>
              <div className="flex items-center gap-2">
                <span className="text-white font-mono">{lastCreatedAccount.email}</span>
                <button
                  onClick={() => handleCopy(lastCreatedAccount.email, 'Email')}
                  className="text-green-400 hover:text-green-300"
                >
                  <Copy className="w-4 h-4" />
                </button>
              </div>
            </div>
            
            <div className="flex justify-between items-center">
              <span className="text-gray-400">Password:</span>
              <div className="flex items-center gap-2">
                <span className="text-white font-mono">{lastCreatedAccount.password}</span>
                <button
                  onClick={() => handleCopy(lastCreatedAccount.password, 'Password')}
                  className="text-green-400 hover:text-green-300"
                >
                  <Copy className="w-4 h-4" />
                </button>
              </div>
            </div>
            
            {lastCreatedAccount.hederaAccountId && (
              <div className="flex justify-between items-center">
                <span className="text-gray-400">Hedera Account:</span>
                <div className="flex items-center gap-2">
                  <span className="text-green-400 font-mono">{lastCreatedAccount.hederaAccountId}</span>
                  <button
                    onClick={() => handleCopy(lastCreatedAccount.hederaAccountId, 'Hedera Account')}
                    className="text-green-400 hover:text-green-300"
                  >
                    <Copy className="w-4 h-4" />
                  </button>
                </div>
              </div>
            )}

            {lastCreatedAccount.warning && (
              <div className="bg-yellow-600/20 border border-yellow-500/50 rounded p-3 mt-3">
                <p className="text-yellow-400 text-xs">{lastCreatedAccount.warning}</p>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Batch Creation Section */}
      <div className="bg-gray-800/50 rounded-xl p-6 border-2 border-purple-500/30">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-bold text-white flex items-center gap-2">
            <Users className="w-5 h-5 text-purple-400" />
            Batch Account Creation
          </h3>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm text-gray-400 mb-2">
              Number of Accounts to Create (Recommended: 1-50)
            </label>
            <input
              type="number"
              min="1"
              max="100"
              value={batchCount}
              onChange={(e) => setBatchCount(Math.min(100, Math.max(1, parseInt(e.target.value) || 1)))}
              disabled={batchCreating}
              className="w-full bg-gray-900 text-white px-4 py-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
            />
            <p className="text-xs text-gray-500 mt-1">
              ⚠️ Each account takes ~3-5 seconds (includes 500ms delay between accounts)
            </p>
          </div>

          {batchCreating && (
            <div className="bg-purple-600/20 border border-purple-500/50 rounded-lg p-4">
              <div className="flex items-center justify-between mb-2">
                <span className="text-white font-semibold">Creating Accounts...</span>
                <span className="text-purple-400 font-bold">
                  {batchProgress.current} / {batchProgress.total}
                </span>
              </div>
              <div className="w-full bg-gray-700 rounded-full h-3 overflow-hidden">
                <div
                  className="h-full bg-gradient-to-r from-purple-600 to-pink-600 transition-all duration-300"
                  style={{ width: `${(batchProgress.current / batchProgress.total) * 100}%` }}
                />
              </div>
              <p className="text-xs text-gray-400 mt-2">
                Estimated time remaining: ~{Math.ceil((batchProgress.total - batchProgress.current) * 3)} seconds
              </p>
            </div>
          )}

          {batchResults && (
            <div className="bg-gray-900 rounded-lg p-4 space-y-2">
              <h4 className="text-white font-bold">Batch Results</h4>
              <div className="grid grid-cols-3 gap-4 text-center">
                <div className="bg-green-600/20 rounded p-3">
                  <div className="text-2xl font-bold text-green-400">{batchResults.successful.length}</div>
                  <div className="text-xs text-gray-400">Successful</div>
                </div>
                <div className="bg-red-600/20 rounded p-3">
                  <div className="text-2xl font-bold text-red-400">{batchResults.failed.length}</div>
                  <div className="text-xs text-gray-400">Failed</div>
                </div>
                <div className="bg-blue-600/20 rounded p-3">
                  <div className="text-2xl font-bold text-blue-400">{batchResults.total}</div>
                  <div className="text-xs text-gray-400">Total</div>
                </div>
              </div>
            </div>
          )}

          <button
            onClick={handleBatchCreate}
            disabled={batchCreating || batchCount < 1}
            className="w-full py-4 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white rounded-lg font-semibold transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            {batchCreating ? (
              <>
                <RefreshCw className="w-5 h-5 animate-spin" />
                Creating {batchCount} Accounts...
              </>
            ) : (
              <>
                <Users className="w-5 h-5" />
                Create {batchCount} Account{batchCount !== 1 ? 's' : ''}
              </>
            )}
          </button>

          {/* Quick Action Buttons */}
          <div className="grid grid-cols-2 gap-3 mt-3">
            <button
              onClick={() => {
                setBatchCount(50);
                setTimeout(() => handleBatchCreate(), 100);
              }}
              disabled={batchCreating}
              className="py-3 bg-gradient-to-r from-orange-600 to-red-600 hover:from-orange-700 hover:to-red-700 text-white rounded-lg font-semibold transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              <Users className="w-4 h-4" />
              Create 50 Accounts
            </button>
            <button
              onClick={() => {
                setBatchCount(100);
                setTimeout(() => handleBatchCreate(), 100);
              }}
              disabled={batchCreating}
              className="py-3 bg-gradient-to-r from-red-600 to-pink-600 hover:from-red-700 hover:to-pink-700 text-white rounded-lg font-semibold transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              <Users className="w-4 h-4" />
              Create 100 Accounts
            </button>
          </div>
        </div>
      </div>

      {/* Info Box */}
      <div className="bg-blue-600/10 border border-blue-500/30 rounded-xl p-4">
        <p className="text-sm text-blue-300">
          <strong>Note:</strong> Generated accounts will automatically receive:
        </p>
        <ul className="list-disc list-inside text-sm text-blue-300 mt-2 space-y-1">
          <li>Firebase Authentication account</li>
          <li>Hedera blockchain wallet</li>
          <li>Initial CNE balance (signup bonus)</li>
          <li>DID (Decentralized Identity)</li>
        </ul>
      </div>
    </div>
  );
};

export default AccountGenerator;
