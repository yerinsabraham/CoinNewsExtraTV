import { useAuthStore } from '../store/authStore'
import { FaPlay, FaNewspaper, FaCoins, FaTrophy } from 'react-icons/fa'
import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'

const DashboardPage = () => {
  const { user } = useAuthStore()

  const stats = [
    { label: 'CNE Tokens', value: user?.cneTokens || 1000, icon: FaCoins, color: 'text-yellow-500' },
    { label: 'Videos Watched', value: 24, icon: FaPlay, color: 'text-blue-500' },
    { label: 'News Read', value: 156, icon: FaNewspaper, color: 'text-green-500' },
    { label: 'Rank', value: '#127', icon: FaTrophy, color: 'text-purple-500' },
  ]

  return (
    <div className="space-y-8">
      {/* Welcome Section */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-xl p-8"
      >
        <h1 className="text-3xl font-bold text-white mb-2">
          Welcome back, {user?.displayName}!
        </h1>
        <p className="text-blue-100">
          Ready to learn and earn today?
        </p>
      </motion.div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, index) => (
          <motion.div
            key={stat.label}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            className="bg-gray-800 rounded-xl p-6 border border-gray-700"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-400 text-sm mb-1">{stat.label}</p>
                <p className="text-3xl font-bold text-white">{stat.value}</p>
              </div>
              <stat.icon className={`text-4xl ${stat.color}`} />
            </div>
          </motion.div>
        ))}
      </div>

      {/* Quick Actions */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
      >
        <h2 className="text-2xl font-bold text-white mb-4">Quick Actions</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Link
            to="/videos"
            className="bg-gray-800 rounded-xl p-6 border border-gray-700 hover:border-blue-500 transition group"
          >
            <FaPlay className="text-blue-500 text-3xl mb-3 group-hover:scale-110 transition" />
            <h3 className="text-xl font-semibold text-white mb-2">Watch Videos</h3>
            <p className="text-gray-400">Earn tokens by watching crypto content</p>
          </Link>

          <Link
            to="/news"
            className="bg-gray-800 rounded-xl p-6 border border-gray-700 hover:border-green-500 transition group"
          >
            <FaNewspaper className="text-green-500 text-3xl mb-3 group-hover:scale-110 transition" />
            <h3 className="text-xl font-semibold text-white mb-2">Read News</h3>
            <p className="text-gray-400">Stay updated with latest crypto news</p>
          </Link>

          <Link
            to="/wallet"
            className="bg-gray-800 rounded-xl p-6 border border-gray-700 hover:border-yellow-500 transition group"
          >
            <FaCoins className="text-yellow-500 text-3xl mb-3 group-hover:scale-110 transition" />
            <h3 className="text-xl font-semibold text-white mb-2">Manage Wallet</h3>
            <p className="text-gray-400">View and manage your CNE tokens</p>
          </Link>
        </div>
      </motion.div>

      {/* Recent Activity */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
        className="bg-gray-800 rounded-xl p-6 border border-gray-700"
      >
        <h2 className="text-2xl font-bold text-white mb-4">Recent Activity</h2>
        <div className="space-y-4">
          <div className="flex items-center justify-between py-3 border-b border-gray-700">
            <div className="flex items-center space-x-3">
              <FaPlay className="text-blue-500" />
              <div>
                <p className="text-white">Watched: Bitcoin 2026 Overview</p>
                <p className="text-sm text-gray-400">2 hours ago</p>
              </div>
            </div>
            <span className="text-green-500 font-semibold">+50 CNE</span>
          </div>
          <div className="flex items-center justify-between py-3 border-b border-gray-700">
            <div className="flex items-center space-x-3">
              <FaNewspaper className="text-green-500" />
              <div>
                <p className="text-white">Read: Ethereum Upgrade News</p>
                <p className="text-sm text-gray-400">5 hours ago</p>
              </div>
            </div>
            <span className="text-green-500 font-semibold">+25 CNE</span>
          </div>
          <div className="flex items-center justify-between py-3">
            <div className="flex items-center space-x-3">
              <FaCoins className="text-yellow-500" />
              <div>
                <p className="text-white">Daily login bonus</p>
                <p className="text-sm text-gray-400">1 day ago</p>
              </div>
            </div>
            <span className="text-green-500 font-semibold">+100 CNE</span>
          </div>
        </div>
      </motion.div>
    </div>
  )
}

export default DashboardPage
