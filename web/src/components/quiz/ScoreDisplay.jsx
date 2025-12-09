import { CheckCircle, XCircle, Award, Clock, TrendingUp } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const ScoreDisplay = ({ result, quiz }) => {
  const navigate = useNavigate();

  const getScoreColor = (percentage) => {
    if (percentage >= 80) return 'text-green-500';
    if (percentage >= 60) return 'text-yellow-500';
    return 'text-red-500';
  };

  const getScoreMessage = (percentage) => {
    if (percentage === 100) return '🎉 Perfect Score!';
    if (percentage >= 80) return '🌟 Excellent!';
    if (percentage >= 60) return '👍 Good Job!';
    if (percentage >= 40) return '💪 Keep Practicing!';
    return '📚 Try Again!';
  };

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className="max-w-3xl mx-auto">
      {/* Score Card */}
      <div className="bg-gradient-to-br from-dark-card to-dark-bg border border-dark-border rounded-xl p-8 mb-6">
        {/* Score Circle */}
        <div className="flex flex-col items-center mb-6">
          <div className={`text-6xl font-black mb-2 ${getScoreColor(result.percentage)}`}>
            {result.percentage}%
          </div>
          <p className="text-2xl font-bold text-white mb-1">
            {getScoreMessage(result.percentage)}
          </p>
          <p className="text-gray-400">
            {result.correctCount} out of {result.totalQuestions} correct
          </p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div className="bg-dark-bg rounded-lg p-4 text-center">
            <div className="flex items-center justify-center gap-2 mb-2">
              <CheckCircle className="w-5 h-5 text-green-500" />
              <span className="text-sm text-gray-400">Correct</span>
            </div>
            <p className="text-2xl font-bold text-white">{result.correctCount}</p>
          </div>

          <div className="bg-dark-bg rounded-lg p-4 text-center">
            <div className="flex items-center justify-center gap-2 mb-2">
              <XCircle className="w-5 h-5 text-red-500" />
              <span className="text-sm text-gray-400">Wrong</span>
            </div>
            <p className="text-2xl font-bold text-white">
              {result.totalQuestions - result.correctCount}
            </p>
          </div>

          <div className="bg-dark-bg rounded-lg p-4 text-center">
            <div className="flex items-center justify-center gap-2 mb-2">
              <Clock className="w-5 h-5 text-blue-500" />
              <span className="text-sm text-gray-400">Time</span>
            </div>
            <p className="text-2xl font-bold text-white">
              {formatTime(result.timeTaken)}
            </p>
          </div>
        </div>

        {/* Reward Display */}
        {result.cneEarned > 0 && (
          <div className="bg-gradient-to-r from-accent-gold/20 to-yellow-600/20 border border-accent-gold/30 rounded-lg p-6 text-center">
            <Award className="w-12 h-12 text-accent-gold mx-auto mb-3" />
            <p className="text-xl font-bold text-white mb-1">
              You Earned {result.cneEarned} CNE!
            </p>
            <p className="text-sm text-gray-300">
              {result.correctCount} correct × 2 CNE each
            </p>
          </div>
        )}
      </div>

      {/* Detailed Results */}
      <div className="bg-dark-card border border-dark-border rounded-xl p-6 mb-6">
        <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
          <TrendingUp className="w-5 h-5" />
          Detailed Results
        </h3>

        <div className="space-y-4">
          {result.results.map((item, index) => (
            <div 
              key={index}
              className={`p-4 rounded-lg border-l-4 ${
                item.isCorrect
                  ? 'bg-green-500/10 border-green-500'
                  : 'bg-red-500/10 border-red-500'
              }`}
            >
              <div className="flex items-start gap-3">
                {item.isCorrect ? (
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0 mt-1" />
                ) : (
                  <XCircle className="w-5 h-5 text-red-500 flex-shrink-0 mt-1" />
                )}
                <div className="flex-1">
                  <p className="text-white font-medium mb-2">
                    {index + 1}. {item.question}
                  </p>
                  <div className="space-y-1 text-sm">
                    <p className={item.isCorrect ? 'text-green-400' : 'text-red-400'}>
                      Your answer: <span className="font-semibold">{item.userAnswer}</span>
                    </p>
                    {!item.isCorrect && (
                      <p className="text-green-400">
                        Correct answer: <span className="font-semibold">{item.correctAnswer}</span>
                      </p>
                    )}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex flex-col sm:flex-row gap-4">
        <button
          onClick={() => navigate(`/quiz/${quiz.id}`)}
          className="flex-1 bg-primary hover:bg-primary-light text-white font-bold py-3 px-6 rounded-lg transition-colors"
        >
          Try Again
        </button>
        <button
          onClick={() => navigate('/quiz')}
          className="flex-1 bg-dark-card hover:bg-dark-border border border-dark-border text-white font-bold py-3 px-6 rounded-lg transition-colors"
        >
          Back to Quizzes
        </button>
      </div>
    </div>
  );
};

export default ScoreDisplay;
