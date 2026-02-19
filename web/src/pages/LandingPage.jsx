import { Link } from 'react-router-dom'
import { motion } from 'framer-motion'
import { FaPlay, FaCoins, FaNewspaper, FaUsers } from 'react-icons/fa'

const LandingPage = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-900 to-gray-900">
      {/* Navigation */}
      <nav className="container mx-auto px-4 py-6 flex justify-between items-center">
        <div className="flex items-center space-x-2">
          <FaPlay className="text-blue-500 text-2xl" />
          <span className="text-white text-2xl font-bold">CoinNewsExtra TV</span>
        </div>
        <div className="space-x-4">
          <Link
            to="/login"
            className="text-white hover:text-blue-400 transition"
          >
            Login
          </Link>
          <Link
            to="/signup"
            className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition"
          >
            Get Started
          </Link>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="container mx-auto px-4 py-20 text-center">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
        >
          <h1 className="text-5xl md:text-7xl font-bold text-white mb-6">
            Watch. Learn. Earn.
          </h1>
          <p className="text-xl md:text-2xl text-gray-300 mb-8 max-w-3xl mx-auto">
            The ultimate crypto news and video platform. Earn CNE tokens while staying updated with the latest in blockchain and cryptocurrency.
          </p>
          <Link
            to="/signup"
            className="inline-block bg-blue-600 text-white px-8 py-4 rounded-lg text-lg font-semibold hover:bg-blue-700 transition transform hover:scale-105"
          >
            Start Earning Now
          </Link>
        </motion.div>
      </section>

      {/* Features Section */}
      <section className="container mx-auto px-4 py-20">
        <div className="grid md:grid-cols-3 gap-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="bg-gray-800 bg-opacity-50 backdrop-blur-lg p-8 rounded-xl"
          >
            <FaPlay className="text-blue-500 text-4xl mb-4" />
            <h3 className="text-2xl font-bold text-white mb-3">Watch Videos</h3>
            <p className="text-gray-300">
              Access exclusive crypto educational content and earn rewards for watching.
            </p>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.3 }}
            className="bg-gray-800 bg-opacity-50 backdrop-blur-lg p-8 rounded-xl"
          >
            <FaNewspaper className="text-blue-500 text-4xl mb-4" />
            <h3 className="text-2xl font-bold text-white mb-3">Read News</h3>
            <p className="text-gray-300">
              Stay updated with the latest crypto news and market insights.
            </p>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.4 }}
            className="bg-gray-800 bg-opacity-50 backdrop-blur-lg p-8 rounded-xl"
          >
            <FaCoins className="text-blue-500 text-4xl mb-4" />
            <h3 className="text-2xl font-bold text-white mb-3">Earn Tokens</h3>
            <p className="text-gray-300">
              Get rewarded with CNE tokens for engaging with content and completing tasks.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="container mx-auto px-4 py-8 text-center text-gray-400">
        <p>&copy; 2026 CoinNewsExtra TV. All rights reserved.</p>
      </footer>
    </div>
  )
}

export default LandingPage
