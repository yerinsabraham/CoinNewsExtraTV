import { FaPlay } from 'react-icons/fa'
import { Link } from 'react-router-dom'

const AuthLayout = ({ children }) => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-900 to-gray-900 flex items-center justify-center px-4">
      <div className="w-full max-w-6xl flex flex-col lg:flex-row items-center gap-12">
        {/* Branding Side */}
        <div className="flex-1 text-center lg:text-left">
          <div className="flex items-center justify-center lg:justify-start space-x-3 mb-6">
            <FaPlay className="text-blue-500 text-4xl" />
            <span className="text-white text-3xl font-bold">CoinNewsExtra TV</span>
          </div>
          <h2 className="text-4xl lg:text-5xl font-bold text-white mb-4">
            Watch. Learn. Earn.
          </h2>
          <p className="text-xl text-gray-300 mb-6">
            Join thousands of users earning CNE tokens while staying updated with the latest crypto news and educational content.
          </p>
          <div className="flex items-center justify-center lg:justify-start space-x-8 text-gray-400">
            <div>
              <p className="text-2xl font-bold text-white">10K+</p>
              <p className="text-sm">Active Users</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-white">500+</p>
              <p className="text-sm">Videos</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-white">1M+</p>
              <p className="text-sm">Tokens Earned</p>
            </div>
          </div>
        </div>

        {/* Form Side */}
        <div className="flex-1 w-full max-w-md">
          <div className="bg-gray-800 bg-opacity-50 backdrop-blur-lg rounded-2xl p-8 border border-gray-700 shadow-2xl">
            {children}
          </div>
        </div>
      </div>
    </div>
  )
}

export default AuthLayout
