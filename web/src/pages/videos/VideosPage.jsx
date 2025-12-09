import { useState, useEffect } from 'react';
import { Search, Filter, TrendingUp, Award, Loader } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { useBalanceStore } from '../../stores/balanceStore';
import videoService from '../../services/video.service';
import VideoGrid from '../../components/videos/VideoGrid';
import toast from 'react-hot-toast';

const VideosPage = () => {
  const { user } = useAuth();
  const balance = useBalanceStore(state => state.balance);
  const [videos, setVideos] = useState([]);
  const [filteredVideos, setFilteredVideos] = useState([]);
  const [watchHistory, setWatchHistory] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [showFilters, setShowFilters] = useState(false);
  
  const categories = videoService.getCategories();

  // Load videos and watch history
  useEffect(() => {
    loadData();
  }, [user]);

  // Filter videos based on search and category
  useEffect(() => {
    filterVideos();
  }, [videos, searchQuery, selectedCategory]);

  const loadData = async () => {
    if (!user) return;

    try {
      setLoading(true);
      
      // Load videos and watch history in parallel
      const [videosData, historyData] = await Promise.all([
        videoService.getVideos(),
        videoService.getWatchHistory(user.uid)
      ]);

      setVideos(videosData);
      setWatchHistory(historyData);
    } catch (error) {
      console.error('Error loading data:', error);
      toast.error('Failed to load videos');
    } finally {
      setLoading(false);
    }
  };

  const filterVideos = () => {
    let filtered = [...videos];

    // Filter by category
    if (selectedCategory !== 'All') {
      filtered = filtered.filter(v => v.category === selectedCategory);
    }

    // Filter by search query
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(v => 
        v.title.toLowerCase().includes(query) ||
        v.description?.toLowerCase().includes(query) ||
        v.category.toLowerCase().includes(query)
      );
    }

    setFilteredVideos(filtered);
  };

  const handleCategoryChange = (category) => {
    setSelectedCategory(category);
  };

  const handleSearchChange = (e) => {
    setSearchQuery(e.target.value);
  };

  const watchedVideoIds = watchHistory
    .filter(h => h.rewarded)
    .map(h => h.videoId);

  const stats = {
    totalVideos: videos.length,
    watchedCount: watchedVideoIds.length,
    earnedFromVideos: watchedVideoIds.length * 7
  };

  return (
    <div className="min-h-screen bg-dark-bg text-white pb-20">
      {/* Header */}
      <div className="bg-gradient-to-r from-primary to-primary-light p-6">
        <div className="max-w-7xl mx-auto">
          <h1 className="text-3xl font-bold mb-2">Watch2Earn Videos</h1>
          <p className="text-gray-200">Watch crypto videos and earn 7 CNE per video!</p>
        </div>
      </div>

      {/* Stats Bar */}
      <div className="bg-dark-card border-b border-dark-border">
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="flex items-center gap-3">
              <div className="bg-primary bg-opacity-20 p-3 rounded-lg">
                <TrendingUp className="w-6 h-6 text-primary" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Total Videos</p>
                <p className="text-xl font-bold">{stats.totalVideos}</p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="bg-accent-gold bg-opacity-20 p-3 rounded-lg">
                <Award className="w-6 h-6 text-accent-gold" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Videos Watched</p>
                <p className="text-xl font-bold">{stats.watchedCount}</p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="bg-green-500 bg-opacity-20 p-3 rounded-lg">
                <Award className="w-6 h-6 text-green-500" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Earned from Videos</p>
                <p className="text-xl font-bold text-accent-gold">{stats.earnedFromVideos} CNE</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-6 py-6">
        {/* Search and Filter Controls */}
        <div className="mb-6 space-y-4">
          {/* Search Bar */}
          <div className="relative">
            <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              placeholder="Search videos by title, description, or category..."
              value={searchQuery}
              onChange={handleSearchChange}
              className="w-full bg-dark-card border border-dark-border rounded-lg pl-12 pr-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          {/* Filter Toggle */}
          <div className="flex items-center justify-between">
            <button
              onClick={() => setShowFilters(!showFilters)}
              className="flex items-center gap-2 bg-dark-card border border-dark-border rounded-lg px-4 py-2 hover:bg-dark-border transition-colors"
            >
              <Filter className="w-4 h-4" />
              <span>Filters</span>
              {selectedCategory !== 'All' && (
                <span className="bg-primary px-2 py-0.5 rounded text-xs">1</span>
              )}
            </button>

            <p className="text-sm text-gray-400">
              Showing {filteredVideos.length} of {stats.totalVideos} videos
            </p>
          </div>

          {/* Category Filters */}
          {showFilters && (
            <div className="bg-dark-card border border-dark-border rounded-lg p-4">
              <p className="text-sm font-semibold mb-3">Categories</p>
              <div className="flex flex-wrap gap-2">
                {categories.map(category => (
                  <button
                    key={category}
                    onClick={() => handleCategoryChange(category)}
                    className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                      selectedCategory === category
                        ? 'bg-primary text-white'
                        : 'bg-dark-bg text-gray-400 hover:bg-dark-border'
                    }`}
                  >
                    {category}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Videos Grid */}
        {loading ? (
          <div className="flex items-center justify-center py-20">
            <Loader className="w-8 h-8 animate-spin text-primary" />
          </div>
        ) : (
          <VideoGrid 
            videos={filteredVideos} 
            watchedVideos={watchedVideoIds}
          />
        )}

        {/* No Results Message */}
        {!loading && filteredVideos.length === 0 && videos.length > 0 && (
          <div className="text-center py-12">
            <p className="text-gray-400 text-lg">No videos match your search</p>
            <button
              onClick={() => {
                setSearchQuery('');
                setSelectedCategory('All');
              }}
              className="mt-4 text-primary hover:underline"
            >
              Clear filters
            </button>
          </div>
        )}

        {/* Info Card */}
        {!loading && filteredVideos.length > 0 && (
          <div className="mt-8 bg-gradient-to-r from-primary to-primary-light rounded-lg p-6">
            <div className="flex items-start gap-4">
              <Award className="w-8 h-8 text-white flex-shrink-0" />
              <div>
                <h3 className="text-xl font-bold text-white mb-2">How Watch2Earn Works</h3>
                <ul className="space-y-2 text-white text-sm">
                  <li className="flex items-center gap-2">
                    <span className="w-2 h-2 bg-white rounded-full"></span>
                    Watch at least 80% of any video to earn 7 CNE
                  </li>
                  <li className="flex items-center gap-2">
                    <span className="w-2 h-2 bg-white rounded-full"></span>
                    Each video can only be rewarded once per account
                  </li>
                  <li className="flex items-center gap-2">
                    <span className="w-2 h-2 bg-white rounded-full"></span>
                    New videos are added regularly - check back often!
                  </li>
                  <li className="flex items-center gap-2">
                    <span className="w-2 h-2 bg-white rounded-full"></span>
                    Your earned CNE is instantly added to your balance
                  </li>
                </ul>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default VideosPage;
