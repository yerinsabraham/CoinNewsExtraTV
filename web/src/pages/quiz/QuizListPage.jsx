import { useState, useEffect } from 'react';
import { Search, Filter, Brain, Award, TrendingUp, Loader } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import quizService from '../../services/quiz.service';
import QuizCard from '../../components/quiz/QuizCard';
import toast from 'react-hot-toast';

const QuizListPage = () => {
  const { user } = useAuth();
  const [quizzes, setQuizzes] = useState([]);
  const [filteredQuizzes, setFilteredQuizzes] = useState([]);
  const [userAttempts, setUserAttempts] = useState([]);
  const [userStats, setUserStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [selectedDifficulty, setSelectedDifficulty] = useState('All');
  const [showFilters, setShowFilters] = useState(false);

  const categories = quizService.getCategories();
  const difficulties = ['All', ...quizService.getDifficulties()];

  useEffect(() => {
    loadData();
  }, [user]);

  useEffect(() => {
    filterQuizzes();
  }, [quizzes, searchQuery, selectedCategory, selectedDifficulty]);

  const loadData = async () => {
    if (!user) return;

    try {
      setLoading(true);
      const [quizzesData, attemptsData, statsData] = await Promise.all([
        quizService.getQuizzes({ active: true }),
        quizService.getUserAttempts(user.uid),
        quizService.getUserStats(user.uid)
      ]);

      setQuizzes(quizzesData);
      setUserAttempts(attemptsData);
      setUserStats(statsData);
    } catch (error) {
      console.error('Error loading data:', error);
      toast.error('Failed to load quizzes');
    } finally {
      setLoading(false);
    }
  };

  const filterQuizzes = () => {
    let filtered = [...quizzes];

    if (selectedCategory !== 'All') {
      filtered = filtered.filter(q => q.category === selectedCategory);
    }

    if (selectedDifficulty !== 'All') {
      filtered = filtered.filter(q => q.difficulty === selectedDifficulty);
    }

    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(q =>
        q.title.toLowerCase().includes(query) ||
        q.description?.toLowerCase().includes(query) ||
        q.category.toLowerCase().includes(query)
      );
    }

    setFilteredQuizzes(filtered);
  };

  const getUserBestScore = (quizId) => {
    const attempts = userAttempts.filter(a => a.quizId === quizId);
    if (attempts.length === 0) return null;
    return Math.max(...attempts.map(a => a.percentage));
  };

  const hasAttempted = (quizId) => {
    return userAttempts.some(a => a.quizId === quizId);
  };

  return (
    <div className="min-h-screen bg-dark-bg text-white pb-20">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-600 to-purple-600 p-6">
        <div className="max-w-7xl mx-auto">
          <h1 className="text-3xl font-bold mb-2">Quiz Challenge</h1>
          <p className="text-gray-200">Test your crypto knowledge and earn 2 CNE per correct answer!</p>
        </div>
      </div>

      {/* User Stats Bar */}
      {userStats && (
        <div className="bg-dark-card border-b border-dark-border">
          <div className="max-w-7xl mx-auto px-6 py-4">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="flex items-center gap-3">
                <div className="bg-primary bg-opacity-20 p-3 rounded-lg">
                  <Brain className="w-6 h-6 text-primary" />
                </div>
                <div>
                  <p className="text-sm text-gray-400">Quizzes Taken</p>
                  <p className="text-xl font-bold">{userStats.totalAttempts}</p>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <div className="bg-green-500 bg-opacity-20 p-3 rounded-lg">
                  <TrendingUp className="w-6 h-6 text-green-500" />
                </div>
                <div>
                  <p className="text-sm text-gray-400">Avg Score</p>
                  <p className="text-xl font-bold">{userStats.averageScore}%</p>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <div className="bg-blue-500 bg-opacity-20 p-3 rounded-lg">
                  <TrendingUp className="w-6 h-6 text-blue-500" />
                </div>
                <div>
                  <p className="text-sm text-gray-400">Best Score</p>
                  <p className="text-xl font-bold">{userStats.bestScore}%</p>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <div className="bg-accent-gold bg-opacity-20 p-3 rounded-lg">
                  <Award className="w-6 h-6 text-accent-gold" />
                </div>
                <div>
                  <p className="text-sm text-gray-400">Total Earned</p>
                  <p className="text-xl font-bold text-accent-gold">{userStats.totalEarned} CNE</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="max-w-7xl mx-auto px-6 py-6">
        {/* Search and Filter Controls */}
        <div className="mb-6 space-y-4">
          {/* Search Bar */}
          <div className="relative">
            <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              placeholder="Search quizzes by title, description, or category..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
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
              {(selectedCategory !== 'All' || selectedDifficulty !== 'All') && (
                <span className="bg-primary px-2 py-0.5 rounded text-xs">
                  {[selectedCategory !== 'All', selectedDifficulty !== 'All'].filter(Boolean).length}
                </span>
              )}
            </button>

            <p className="text-sm text-gray-400">
              Showing {filteredQuizzes.length} of {quizzes.length} quizzes
            </p>
          </div>

          {/* Filters */}
          {showFilters && (
            <div className="bg-dark-card border border-dark-border rounded-lg p-4 space-y-4">
              {/* Category Filter */}
              <div>
                <p className="text-sm font-semibold mb-3">Category</p>
                <div className="flex flex-wrap gap-2">
                  {categories.map(category => (
                    <button
                      key={category}
                      onClick={() => setSelectedCategory(category)}
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

              {/* Difficulty Filter */}
              <div>
                <p className="text-sm font-semibold mb-3">Difficulty</p>
                <div className="flex flex-wrap gap-2">
                  {difficulties.map(difficulty => (
                    <button
                      key={difficulty}
                      onClick={() => setSelectedDifficulty(difficulty)}
                      className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                        selectedDifficulty === difficulty
                          ? 'bg-primary text-white'
                          : 'bg-dark-bg text-gray-400 hover:bg-dark-border'
                      }`}
                    >
                      {difficulty}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Quizzes Grid */}
        {loading ? (
          <div className="flex items-center justify-center py-20">
            <Loader className="w-8 h-8 animate-spin text-primary" />
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {filteredQuizzes.map(quiz => (
              <QuizCard
                key={quiz.id}
                quiz={quiz}
                attempted={hasAttempted(quiz.id)}
                userBestScore={getUserBestScore(quiz.id)}
              />
            ))}
          </div>
        )}

        {/* No Results */}
        {!loading && filteredQuizzes.length === 0 && quizzes.length > 0 && (
          <div className="text-center py-12">
            <p className="text-gray-400 text-lg">No quizzes match your search</p>
            <button
              onClick={() => {
                setSearchQuery('');
                setSelectedCategory('All');
                setSelectedDifficulty('All');
              }}
              className="mt-4 text-primary hover:underline"
            >
              Clear filters
            </button>
          </div>
        )}

        {/* Empty State */}
        {!loading && quizzes.length === 0 && (
          <div className="text-center py-12">
            <Brain className="w-16 h-16 text-gray-600 mx-auto mb-4" />
            <p className="text-gray-400 text-lg">No quizzes available yet</p>
            <p className="text-gray-500 text-sm mt-2">Check back later for new challenges!</p>
          </div>
        )}

        {/* Info Card */}
        {!loading && filteredQuizzes.length > 0 && (
          <div className="mt-8 bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg p-6">
            <div className="flex items-start gap-4">
              <Brain className="w-8 h-8 text-white flex-shrink-0" />
              <div>
                <h3 className="text-xl font-bold text-white mb-2">How Quiz Challenge Works</h3>
                <ul className="space-y-2 text-white text-sm">
                  <li className="flex items-center gap-2">
                    <span className="w-2 h-2 bg-white rounded-full"></span>
                    Answer questions correctly to earn 2 CNE per question
                  </li>
                  <li className="flex items-center gap-2">
                    <span className="w-2 h-2 bg-white rounded-full"></span>
                    Complete quizzes within the time limit for best results
                  </li>
                  <li className="flex items-center gap-2">
                    <span className="w-2 h-2 bg-white rounded-full"></span>
                    You can retake quizzes to improve your score
                  </li>
                  <li className="flex items-center gap-2">
                    <span className="w-2 h-2 bg-white rounded-full"></span>
                    New quizzes are added regularly - keep learning!
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

export default QuizListPage;
