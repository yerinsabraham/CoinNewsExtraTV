import { Link, useLocation } from 'react-router-dom'
import { useAuthStore } from '../../store/authStore'
import { FaHome, FaPlay, FaNewspaper, FaWallet, FaUser, FaBars, FaTimes } from 'react-icons/fa'
import { useState } from 'react'

const MainLayout = ({ children }) => {
  const { user } = useAuthStore()
  const location = useLocation()
  const [sidebarOpen, setSidebarOpen] = useState(false)

  const navigation = [
    { name: 'Dashboard', path: '/dashboard', icon: FaHome },
    { name: 'Videos', path: '/videos', icon: FaPlay },
    { name: 'News', path: '/news', icon: FaNewspaper },
    { name: 'Wallet', path: '/wallet', icon: FaWallet },
    { name: 'Profile', path: '/profile', icon: FaUser },
  ]

  const isActive = (path) => location.pathname === path

  return (
    <div className="min-h-screen bg-gray-900">
      {/* Mobile Menu Button */}
      <button
        onClick={() => setSidebarOpen(!sidebarOpen)}
        className="lg:hidden fixed top-4 left-4 z-50 bg-gray-800 text-white p-3 rounded-lg"
      >
        {sidebarOpen ? <FaTimes /> : <FaBars />}
      </button>

      {/* Sidebar */}
      <aside
        className={`fixed top-0 left-0 h-full bg-gray-800 border-r border-gray-700 w-64 transform transition-transform duration-300 z-40 ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        } lg:translate-x-0`}
      >
        <div className="p-6">
          <Link to="/dashboard" className="flex items-center space-x-2 mb-8">
            <FaPlay className="text-blue-500 text-2xl" />
            <span className="text-white text-xl font-bold">CNE TV</span>
          </Link>

          <nav className="space-y-2">
            {navigation.map((item) => {
              const Icon = item.icon
              return (
                <Link
                  key={item.path}
                  to={item.path}
                  onClick={() => setSidebarOpen(false)}
                  className={`flex items-center space-x-3 px-4 py-3 rounded-lg transition ${
                    isActive(item.path)
                      ? 'bg-blue-600 text-white'
                      : 'text-gray-400 hover:bg-gray-700 hover:text-white'
                  }`}
                >
                  <Icon />
                  <span>{item.name}</span>
                </Link>
              )
            })}
          </nav>
        </div>

        <div className="absolute bottom-0 left-0 right-0 p-6 border-t border-gray-700">
          <div className="flex items-center space-x-3">
            {user?.photoURL ? (
              <img
                src={user.photoURL}
                alt={user.displayName}
                className="w-10 h-10 rounded-full"
              />
            ) : (
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white font-bold">
                {user?.displayName?.charAt(0).toUpperCase()}
              </div>
            )}
            <div className="flex-1 min-w-0">
              <p className="text-white text-sm font-medium truncate">
                {user?.displayName}
              </p>
              <p className="text-gray-400 text-xs truncate">{user?.email}</p>
            </div>
          </div>
        </div>
      </aside>

      {/* Overlay */}
      {sidebarOpen && (
        <div
          onClick={() => setSidebarOpen(false)}
          className="lg:hidden fixed inset-0 bg-black bg-opacity-50 z-30"
        />
      )}

      {/* Main Content */}
      <main className="lg:ml-64 min-h-screen">
        <div className="container mx-auto px-4 py-8 lg:px-8 lg:py-12">
          {children}
        </div>
      </main>
    </div>
  )
}

export default MainLayout
