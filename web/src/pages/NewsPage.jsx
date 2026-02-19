import { motion } from 'framer-motion'
import { FaNewspaper, FaClock, FaArrowRight } from 'react-icons/fa'
import { formatRelativeTime } from '../lib/utils'

const NewsPage = () => {
  const mockNews = [
    {
      id: 1,
      title: 'Bitcoin Reaches New All-Time High in 2026',
      excerpt: 'Bitcoin has surpassed previous records, reaching unprecedented levels as institutional adoption continues to grow...',
      image: 'https://via.placeholder.com/400x250/1e40af/ffffff?text=Bitcoin+News',
      category: 'Bitcoin',
      readTime: 5,
      reward: 25,
      publishedAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
    },
    {
      id: 2,
      title: 'Ethereum 3.0 Roadmap Unveiled',
      excerpt: 'The Ethereum Foundation announces major upgrades planned for the network, focusing on scalability and efficiency...',
      image: 'https://via.placeholder.com/400x250/7c3aed/ffffff?text=Ethereum+News',
      category: 'Ethereum',
      readTime: 7,
      reward: 30,
      publishedAt: new Date(Date.now() - 5 * 60 * 60 * 1000),
    },
    {
      id: 3,
      title: 'Major Banks Announce Blockchain Integration',
      excerpt: 'Leading financial institutions reveal plans to integrate blockchain technology into their core operations...',
      image: 'https://via.placeholder.com/400x250/059669/ffffff?text=Banking+News',
      category: 'DeFi',
      readTime: 6,
      reward: 28,
      publishedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
    },
    {
      id: 4,
      title: 'NFT Marketplace Launches Revolutionary Features',
      excerpt: 'New platform introduces groundbreaking features for NFT creators and collectors, disrupting the market...',
      image: 'https://via.placeholder.com/400x250/dc2626/ffffff?text=NFT+News',
      category: 'NFTs',
      readTime: 4,
      reward: 20,
      publishedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    },
    {
      id: 5,
      title: 'Hedera Hashgraph Adoption Surges',
      excerpt: 'Enterprise adoption of Hedera network reaches new milestones as major corporations join the ecosystem...',
      image: 'https://via.placeholder.com/400x250/8b5cf6/ffffff?text=Hedera+News',
      category: 'Hedera',
      readTime: 5,
      reward: 25,
      publishedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    },
    {
      id: 6,
      title: 'Global Crypto Regulations: What You Need to Know',
      excerpt: 'Comprehensive overview of new cryptocurrency regulations being implemented worldwide and their impact...',
      image: 'https://via.placeholder.com/400x250/f59e0b/ffffff?text=Regulation+News',
      category: 'Regulation',
      readTime: 8,
      reward: 35,
      publishedAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
    },
  ]

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white mb-2">Latest Crypto News</h1>
        <p className="text-gray-400">Stay informed and earn CNE tokens by reading articles</p>
      </div>

      {/* Featured Article */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-gray-800 rounded-xl overflow-hidden border border-gray-700 hover:border-blue-500 transition cursor-pointer"
      >
        <div className="md:flex">
          <div className="md:w-1/2">
            <img
              src={mockNews[0].image}
              alt={mockNews[0].title}
              className="w-full h-64 md:h-full object-cover"
            />
          </div>
          <div className="p-8 md:w-1/2">
            <div className="flex items-center space-x-3 mb-4">
              <span className="bg-blue-600 text-white text-xs px-3 py-1 rounded-full">
                {mockNews[0].category}
              </span>
              <span className="text-gray-400 text-sm flex items-center space-x-1">
                <FaClock />
                <span>{mockNews[0].readTime} min read</span>
              </span>
            </div>
            <h2 className="text-2xl font-bold text-white mb-3">{mockNews[0].title}</h2>
            <p className="text-gray-400 mb-4">{mockNews[0].excerpt}</p>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-500">
                {formatRelativeTime(mockNews[0].publishedAt)}
              </span>
              <button className="flex items-center space-x-2 text-blue-500 hover:text-blue-400">
                <span className="font-semibold">+{mockNews[0].reward} CNE</span>
                <FaArrowRight />
              </button>
            </div>
          </div>
        </div>
      </motion.div>

      {/* News Grid */}
      <div>
        <h2 className="text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <FaNewspaper className="text-blue-500" />
          <span>Recent Articles</span>
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {mockNews.slice(1).map((article, index) => (
            <motion.div
              key={article.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              className="bg-gray-800 rounded-xl overflow-hidden border border-gray-700 hover:border-blue-500 transition cursor-pointer group"
            >
              <div className="relative h-48 bg-gray-700 overflow-hidden">
                <img
                  src={article.image}
                  alt={article.title}
                  className="w-full h-full object-cover group-hover:scale-105 transition duration-300"
                />
                <div className="absolute top-3 left-3">
                  <span className="bg-blue-600 text-white text-xs px-3 py-1 rounded-full">
                    {article.category}
                  </span>
                </div>
              </div>
              <div className="p-5">
                <h3 className="text-white font-semibold mb-2 line-clamp-2">
                  {article.title}
                </h3>
                <p className="text-gray-400 text-sm mb-4 line-clamp-2">
                  {article.excerpt}
                </p>
                <div className="flex items-center justify-between text-sm">
                  <div className="flex items-center space-x-3 text-gray-500">
                    <span className="flex items-center space-x-1">
                      <FaClock />
                      <span>{article.readTime} min</span>
                    </span>
                    <span>{formatRelativeTime(article.publishedAt)}</span>
                  </div>
                  <span className="text-yellow-500 font-semibold">+{article.reward} CNE</span>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </div>
  )
}

export default NewsPage
