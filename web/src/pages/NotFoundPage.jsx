import { Link } from 'react-router-dom'
import { FaHome } from 'react-icons/fa'

const NotFoundPage = () => {
  return (
    <div className="min-h-screen bg-gray-900 flex items-center justify-center px-4">
      <div className="text-center">
        <h1 className="text-9xl font-bold text-blue-500 mb-4">404</h1>
        <h2 className="text-4xl font-bold text-white mb-4">Page Not Found</h2>
        <p className="text-gray-400 mb-8 max-w-md mx-auto">
          The page you're looking for doesn't exist or has been moved.
        </p>
        <Link
          to="/"
          className="inline-flex items-center space-x-2 bg-blue-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-blue-700 transition"
        >
          <FaHome />
          <span>Go Home</span>
        </Link>
      </div>
    </div>
  )
}

export default NotFoundPage
