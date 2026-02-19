import { useState } from 'react'
import { motion } from 'framer-motion'
import { FaPlay, FaClock, FaFire } from 'react-icons/fa'
import ReactPlayer from 'react-player'

const VideosPage = () => {
  const [selectedVideo, setSelectedVideo] = useState(null)

  const mockVideos = [
    {
      id: 1,
      title: 'Bitcoin 2026: What\'s Next?',
      thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
      url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      duration: '12:45',
      reward: 50,
      views: 12500,
    },
    {
      id: 2,
      title: 'Ethereum Layer 2 Solutions Explained',
      thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
      url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      duration: '15:30',
      reward: 60,
      views: 8900,
    },
    {
      id: 3,
      title: 'DeFi Basics for Beginners',
      thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
      url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      duration: '18:20',
      reward: 75,
      views: 15200,
    },
    {
      id: 4,
      title: 'NFT Market Trends 2026',
      thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
      url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      duration: '10:15',
      reward: 45,
      views: 6700,
    },
  ]

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white mb-2">Watch & Earn</h1>
        <p className="text-gray-400">Earn CNE tokens by watching educational crypto content</p>
      </div>

      {/* Video Player */}
      {selectedVideo && (
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="bg-gray-800 rounded-xl overflow-hidden border border-gray-700"
        >
          <div className="aspect-video bg-black">
            <ReactPlayer
              url={selectedVideo.url}
              width="100%"
              height="100%"
              controls
              playing
            />
          </div>
          <div className="p-6">
            <h2 className="text-2xl font-bold text-white mb-2">{selectedVideo.title}</h2>
            <div className="flex items-center space-x-4 text-gray-400">
              <span className="flex items-center space-x-1">
                <FaClock />
                <span>{selectedVideo.duration}</span>
              </span>
              <span>•</span>
              <span>{selectedVideo.views.toLocaleString()} views</span>
              <span>•</span>
              <span className="text-yellow-500 font-semibold">
                +{selectedVideo.reward} CNE
              </span>
            </div>
          </div>
        </motion.div>
      )}

      {/* Video Grid */}
      <div>
        <h2 className="text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <FaFire className="text-orange-500" />
          <span>Trending Videos</span>
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {mockVideos.map((video, index) => (
            <motion.div
              key={video.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              onClick={() => setSelectedVideo(video)}
              className="bg-gray-800 rounded-xl overflow-hidden border border-gray-700 cursor-pointer hover:border-blue-500 transition group"
            >
              <div className="relative aspect-video bg-gray-700">
                <img
                  src={video.thumbnail}
                  alt={video.title}
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-black bg-opacity-40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition">
                  <FaPlay className="text-white text-4xl" />
                </div>
                <div className="absolute bottom-2 right-2 bg-black bg-opacity-75 text-white text-xs px-2 py-1 rounded">
                  {video.duration}
                </div>
              </div>
              <div className="p-4">
                <h3 className="text-white font-semibold mb-2 line-clamp-2">
                  {video.title}
                </h3>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-400">{video.views.toLocaleString()} views</span>
                  <span className="text-yellow-500 font-semibold">+{video.reward} CNE</span>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </div>
  )
}

export default VideosPage
