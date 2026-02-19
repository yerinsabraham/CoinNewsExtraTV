import { useAuthStore } from '../store/authStore'
import { motion } from 'framer-motion'
import { FaCoins, FaArrowUp, FaArrowDown, FaWallet, FaCopy } from 'react-icons/fa'
import { useState } from 'react'
import toast from 'react-hot-toast'
import { copyToClipboard } from '../lib/utils'

const WalletPage = () => {
  const { user } = useAuthStore()
  const [showWithdraw, setShowWithdraw] = useState(false)

  const mockTransactions = [
    {
      id: 1,
      type: 'earn',
      description: 'Video Watch Reward',
      amount: 50,
      date: new Date(Date.now() - 2 * 60 * 60 * 1000),
    },
    {
      id: 2,
      type: 'earn',
      description: 'News Reading Reward',
      amount: 25,
      date: new Date(Date.now() - 5 * 60 * 60 * 1000),
    },
    {
      id: 3,
      type: 'earn',
      description: 'Daily Login Bonus',
      amount: 100,
      date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
    },
    {
      id: 4,
      type: 'withdraw',
      description: 'Withdraw to Hedera',
      amount: -500,
      date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    },
  ]

  const handleCopyAddress = async () => {
    if (user?.hederaAccountId) {
      const success = await copyToClipboard(user.hederaAccountId)
      if (success) {
        toast.success('Hedera Account ID copied!')
      }
    }
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white mb-2">My Wallet</h1>
        <p className="text-gray-400">Manage your CNE tokens and transactions</p>
      </div>

      {/* Balance Card */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-gradient-to-br from-yellow-600 to-orange-600 rounded-xl p-8"
      >
        <div className="flex items-center space-x-2 mb-4">
          <FaWallet className="text-white text-2xl" />
          <span className="text-white text-lg">CNE Balance</span>
        </div>
        <div className="text-5xl font-bold text-white mb-6">
          {(user?.cneTokens || 1000).toLocaleString()} CNE
        </div>
        <div className="flex space-x-4">
          <button
            onClick={() => toast.success('Deposit feature coming soon!')}
            className="flex-1 bg-white text-yellow-700 font-semibold py-3 rounded-lg hover:bg-gray-100 transition flex items-center justify-center space-x-2"
          >
            <FaArrowDown />
            <span>Deposit</span>
          </button>
          <button
            onClick={() => setShowWithdraw(!showWithdraw)}
            className="flex-1 bg-yellow-800 text-white font-semibold py-3 rounded-lg hover:bg-yellow-900 transition flex items-center justify-center space-x-2"
          >
            <FaArrowUp />
            <span>Withdraw</span>
          </button>
        </div>
      </motion.div>

      {/* Hedera Account */}
      {user?.hederaAccountId && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-gray-800 rounded-xl p-6 border border-gray-700"
        >
          <h2 className="text-xl font-bold text-white mb-4">Hedera Account</h2>
          <div className="flex items-center justify-between bg-gray-700 rounded-lg p-4">
            <code className="text-gray-300 font-mono">
              {user.hederaAccountId}
            </code>
            <button
              onClick={handleCopyAddress}
              className="text-blue-500 hover:text-blue-400 transition"
            >
              <FaCopy className="text-xl" />
            </button>
          </div>
        </motion.div>
      )}

      {/* Withdraw Form */}
      {showWithdraw && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: 'auto' }}
          className="bg-gray-800 rounded-xl p-6 border border-gray-700"
        >
          <h2 className="text-xl font-bold text-white mb-4">Withdraw CNE Tokens</h2>
          <form
            onSubmit={(e) => {
              e.preventDefault()
              toast.success('Withdrawal request submitted!')
              setShowWithdraw(false)
            }}
            className="space-y-4"
          >
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Hedera Account ID
              </label>
              <input
                type="text"
                placeholder="0.0.1234567"
                className="w-full bg-gray-700 text-white px-4 py-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-yellow-500"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Amount (CNE)
              </label>
              <input
                type="number"
                placeholder="100"
                min="100"
                max={user?.cneTokens || 1000}
                className="w-full bg-gray-700 text-white px-4 py-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-yellow-500"
                required
              />
              <p className="text-gray-400 text-sm mt-2">
                Minimum withdrawal: 100 CNE
              </p>
            </div>
            <button
              type="submit"
              className="w-full bg-yellow-600 text-white py-3 rounded-lg font-semibold hover:bg-yellow-700 transition"
            >
              Confirm Withdrawal
            </button>
          </form>
        </motion.div>
      )}

      {/* Transaction History */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="bg-gray-800 rounded-xl p-6 border border-gray-700"
      >
        <h2 className="text-2xl font-bold text-white mb-4">Transaction History</h2>
        <div className="space-y-3">
          {mockTransactions.map((transaction) => (
            <div
              key={transaction.id}
              className="flex items-center justify-between py-3 border-b border-gray-700 last:border-0"
            >
              <div className="flex items-center space-x-3">
                <div
                  className={`p-2 rounded-full ${
                    transaction.type === 'earn'
                      ? 'bg-green-500 bg-opacity-20'
                      : 'bg-red-500 bg-opacity-20'
                  }`}
                >
                  {transaction.type === 'earn' ? (
                    <FaArrowDown className="text-green-500" />
                  ) : (
                    <FaArrowUp className="text-red-500" />
                  )}
                </div>
                <div>
                  <p className="text-white">{transaction.description}</p>
                  <p className="text-sm text-gray-400">
                    {transaction.date.toLocaleDateString('en-US', {
                      month: 'short',
                      day: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </p>
                </div>
              </div>
              <span
                className={`font-bold ${
                  transaction.type === 'earn' ? 'text-green-500' : 'text-red-500'
                }`}
              >
                {transaction.amount > 0 ? '+' : ''}
                {transaction.amount} CNE
              </span>
            </div>
          ))}
        </div>
      </motion.div>
    </div>
  )
}

export default WalletPage
