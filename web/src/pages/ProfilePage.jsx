import { useAuthStore } from '../store/authStore'
import { motion } from 'framer-motion'
import { FaUser, FaEnvelope, FaCoins, FaCalendar, FaEdit, FaSignOutAlt } from 'react-icons/fa'
import { useNavigate } from 'react-router-dom'
import { useState } from 'react'

const ProfilePage = () => {
  const { user, signOut } = useAuthStore()
  const navigate = useNavigate()
  const [isEditing, setIsEditing] = useState(false)

  const handleSignOut = async () => {
    await signOut()
    navigate('/')
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white mb-2">My Profile</h1>
        <p className="text-gray-400">Manage your account settings</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Profile Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="lg:col-span-1"
        >
          <div className="bg-gray-800 rounded-xl p-6 border border-gray-700 text-center">
            <div className="relative inline-block mb-4">
              {user?.photoURL ? (
                <img
                  src={user.photoURL}
                  alt={user.displayName}
                  className="w-24 h-24 rounded-full object-cover border-4 border-blue-500"
                />
              ) : (
                <div className="w-24 h-24 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white text-3xl font-bold border-4 border-blue-500">
                  {user?.displayName?.charAt(0).toUpperCase()}
                </div>
              )}
              <button className="absolute bottom-0 right-0 bg-blue-600 p-2 rounded-full text-white hover:bg-blue-700 transition">
                <FaEdit />
              </button>
            </div>
            <h2 className="text-2xl font-bold text-white mb-1">{user?.displayName}</h2>
            <p className="text-gray-400 mb-4">{user?.email}</p>
            <div className="bg-gray-700 rounded-lg p-4 mb-4">
              <div className="flex items-center justify-center space-x-2 text-yellow-500">
                <FaCoins className="text-2xl" />
                <span className="text-2xl font-bold">{user?.cneTokens || 1000}</span>
              </div>
              <p className="text-gray-400 text-sm mt-1">CNE Tokens</p>
            </div>
            <button
              onClick={handleSignOut}
              className="w-full bg-red-600 text-white py-3 rounded-lg font-semibold hover:bg-red-700 transition flex items-center justify-center space-x-2"
            >
              <FaSignOutAlt />
              <span>Sign Out</span>
            </button>
          </div>
        </motion.div>

        {/* Details Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="lg:col-span-2 space-y-6"
        >
          {/* Account Information */}
          <div className="bg-gray-800 rounded-xl p-6 border border-gray-700">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-bold text-white">Account Information</h3>
              <button
                onClick={() => setIsEditing(!isEditing)}
                className="text-blue-500 hover:text-blue-400 transition flex items-center space-x-2"
              >
                <FaEdit />
                <span>{isEditing ? 'Cancel' : 'Edit'}</span>
              </button>
            </div>

            <div className="space-y-4">
              <div className="flex items-start space-x-3 py-3 border-b border-gray-700">
                <FaUser className="text-gray-400 mt-1" />
                <div className="flex-1">
                  <p className="text-gray-400 text-sm">Display Name</p>
                  {isEditing ? (
                    <input
                      type="text"
                      defaultValue={user?.displayName}
                      className="mt-1 w-full bg-gray-700 text-white px-3 py-2 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  ) : (
                    <p className="text-white font-medium">{user?.displayName}</p>
                  )}
                </div>
              </div>

              <div className="flex items-start space-x-3 py-3 border-b border-gray-700">
                <FaEnvelope className="text-gray-400 mt-1" />
                <div className="flex-1">
                  <p className="text-gray-400 text-sm">Email Address</p>
                  <p className="text-white font-medium">{user?.email}</p>
                </div>
              </div>

              <div className="flex items-start space-x-3 py-3 border-b border-gray-700">
                <FaCalendar className="text-gray-400 mt-1" />
                <div className="flex-1">
                  <p className="text-gray-400 text-sm">Member Since</p>
                  <p className="text-white font-medium">
                    {user?.createdAt
                      ? new Date(user.createdAt.seconds * 1000).toLocaleDateString('en-US', {
                          month: 'long',
                          year: 'numeric',
                        })
                      : 'February 2026'}
                  </p>
                </div>
              </div>

              <div className="flex items-start space-x-3 py-3">
                <FaCoins className="text-gray-400 mt-1" />
                <div className="flex-1">
                  <p className="text-gray-400 text-sm">Hedera Account ID</p>
                  <p className="text-white font-medium font-mono">
                    {user?.hederaAccountId || 'Not connected'}
                  </p>
                </div>
              </div>
            </div>

            {isEditing && (
              <button className="mt-6 w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 transition">
                Save Changes
              </button>
            )}
          </div>

          {/* Statistics */}
          <div className="bg-gray-800 rounded-xl p-6 border border-gray-700">
            <h3 className="text-xl font-bold text-white mb-6">Activity Statistics</h3>
            <div className="grid grid-cols-2 gap-4">
              <div className="bg-gray-700 rounded-lg p-4 text-center">
                <p className="text-3xl font-bold text-blue-500 mb-1">24</p>
                <p className="text-gray-400 text-sm">Videos Watched</p>
              </div>
              <div className="bg-gray-700 rounded-lg p-4 text-center">
                <p className="text-3xl font-bold text-green-500 mb-1">156</p>
                <p className="text-gray-400 text-sm">Articles Read</p>
              </div>
              <div className="bg-gray-700 rounded-lg p-4 text-center">
                <p className="text-3xl font-bold text-yellow-500 mb-1">1,250</p>
                <p className="text-gray-400 text-sm">Total Earned</p>
              </div>
              <div className="bg-gray-700 rounded-lg p-4 text-center">
                <p className="text-3xl font-bold text-purple-500 mb-1">7</p>
                <p className="text-gray-400 text-sm">Days Streak</p>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  )
}

export default ProfilePage
