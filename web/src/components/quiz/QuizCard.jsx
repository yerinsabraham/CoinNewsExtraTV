import { Brain, Clock, Award, TrendingUp } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const QuizCard = ({ quiz, attempted = false, userBestScore = null }) => {
  const navigate = useNavigate();

  const getDifficultyColor = (difficulty) => {
    switch (difficulty?.toLowerCase()) {
      case 'easy': return 'text-green-500 bg-green-500/20';
      case 'medium': return 'text-yellow-500 bg-yellow-500/20';
      case 'hard': return 'text-red-500 bg-red-500/20';
      default: return 'text-gray-500 bg-gray-500/20';
    }
  };

  const handleClick = () => {
    navigate(`/quiz/${quiz.id}`);
  };

  return (
    <div 
      onClick={handleClick}
      className="bg-dark-card rounded-lg overflow-hidden cursor-pointer transform transition-all duration-300 hover:scale-105 hover:shadow-xl border border-dark-border"
    >
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-600 to-purple-600 p-4">
        <div className="flex items-start justify-between mb-2">
          <div className="bg-white/20 p-2 rounded-lg">
            <Brain className="w-6 h-6 text-white" />
          </div>
          <span className={`px-2 py-1 rounded text-xs font-bold ${getDifficultyColor(quiz.difficulty)}`}>
            {quiz.difficulty || 'Medium'}
          </span>
        </div>
        <h3 className="font-bold text-white text-lg line-clamp-2">
          {quiz.title}
        </h3>
      </div>

      {/* Content */}
      <div className="p-4">
        <p className="text-gray-400 text-sm line-clamp-2 mb-4">
          {quiz.description}
        </p>

        <div className="space-y-2 mb-4">
          {/* Questions count */}
          <div className="flex items-center justify-between text-sm">
            <span className="text-gray-400">Questions:</span>
            <span className="text-white font-semibold">{quiz.questionCount || 10}</span>
          </div>

          {/* Time limit */}
          {quiz.timeLimit && (
            <div className="flex items-center justify-between text-sm">
              <span className="text-gray-400 flex items-center gap-1">
                <Clock className="w-3 h-3" />
                Time Limit:
              </span>
              <span className="text-white font-semibold">{quiz.timeLimit} mins</span>
            </div>
          )}

          {/* Reward */}
          <div className="flex items-center justify-between text-sm">
            <span className="text-gray-400 flex items-center gap-1">
              <Award className="w-3 h-3" />
              Max Reward:
            </span>
            <span className="text-accent-gold font-bold">
              {(quiz.questionCount || 10) * 2} CNE
            </span>
          </div>
        </div>

        {/* Category */}
        <div className="flex items-center justify-between">
          <span className="text-xs bg-dark-bg px-2 py-1 rounded text-primary-light">
            {quiz.category}
          </span>

          {/* Best Score */}
          {attempted && userBestScore !== null && (
            <div className="flex items-center gap-1 text-sm">
              <TrendingUp className="w-4 h-4 text-green-500" />
              <span className="text-white font-semibold">{userBestScore}%</span>
            </div>
          )}
        </div>

        {/* Status Badge */}
        {attempted && (
          <div className="mt-3 text-center">
            <span className="inline-block text-xs bg-primary/20 text-primary px-3 py-1 rounded-full font-semibold">
              Attempted
            </span>
          </div>
        )}
      </div>
    </div>
  );
};

export default QuizCard;
