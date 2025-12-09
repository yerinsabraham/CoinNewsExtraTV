import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Loader, Play } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { useBalanceStore } from '../../stores/balanceStore';
import quizService from '../../services/quiz.service';
import QuestionDisplay from '../../components/quiz/QuestionDisplay';
import Timer from '../../components/quiz/Timer';
import ScoreDisplay from '../../components/quiz/ScoreDisplay';
import toast from 'react-hot-toast';

const QuizPlayPage = () => {
  const { quizId } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const addReward = useBalanceStore(state => state.addReward);

  const [quiz, setQuiz] = useState(null);
  const [loading, setLoading] = useState(true);
  const [quizStarted, setQuizStarted] = useState(false);
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [answers, setAnswers] = useState([]);
  const [startTime, setStartTime] = useState(null);
  const [quizResult, setQuizResult] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    loadQuiz();
  }, [quizId]);

  const loadQuiz = async () => {
    try {
      setLoading(true);
      const quizData = await quizService.getQuizById(quizId);
      setQuiz(quizData);
      setAnswers(new Array(quizData.questions.length).fill(null));
    } catch (error) {
      console.error('Error loading quiz:', error);
      toast.error('Failed to load quiz');
      navigate('/quiz');
    } finally {
      setLoading(false);
    }
  };

  const handleStartQuiz = () => {
    setQuizStarted(true);
    setStartTime(Date.now());
  };

  const handleSelectAnswer = (answer) => {
    const newAnswers = [...answers];
    newAnswers[currentQuestionIndex] = answer;
    setAnswers(newAnswers);
  };

  const handleNextQuestion = () => {
    if (currentQuestionIndex < quiz.questions.length - 1) {
      setCurrentQuestionIndex(currentQuestionIndex + 1);
    }
  };

  const handlePreviousQuestion = () => {
    if (currentQuestionIndex > 0) {
      setCurrentQuestionIndex(currentQuestionIndex - 1);
    }
  };

  const handleSubmitQuiz = async () => {
    // Check if all questions are answered
    const unanswered = answers.filter(a => a === null).length;
    if (unanswered > 0) {
      toast.error(`Please answer all questions (${unanswered} remaining)`);
      return;
    }

    try {
      setSubmitting(true);
      const timeTaken = Math.floor((Date.now() - startTime) / 1000);
      
      const result = await quizService.submitQuiz(
        user.uid,
        quizId,
        answers,
        quiz.questions,
        timeTaken
      );

      // Update local balance
      if (result.cneEarned > 0) {
        addReward(result.cneEarned, 'quiz');
        toast.success(`Earned ${result.cneEarned} CNE!`);
      }

      setQuizResult(result);
    } catch (error) {
      console.error('Error submitting quiz:', error);
      toast.error('Failed to submit quiz');
    } finally {
      setSubmitting(false);
    }
  };

  const handleTimeUp = () => {
    toast.error('Time\'s up!');
    handleSubmitQuiz();
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <Loader className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!quiz) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <div className="text-center">
          <p className="text-gray-400 text-lg mb-4">Quiz not found</p>
          <button
            onClick={() => navigate('/quiz')}
            className="text-primary hover:underline"
          >
            Back to Quizzes
          </button>
        </div>
      </div>
    );
  }

  // Show results if quiz is completed
  if (quizResult) {
    return (
      <div className="min-h-screen bg-dark-bg text-white pb-20">
        <div className="bg-dark-card border-b border-dark-border">
          <div className="max-w-6xl mx-auto px-6 py-4">
            <button
              onClick={() => navigate('/quiz')}
              className="flex items-center gap-2 text-gray-400 hover:text-white transition-colors"
            >
              <ArrowLeft className="w-5 h-5" />
              <span>Back to Quizzes</span>
            </button>
          </div>
        </div>

        <div className="max-w-6xl mx-auto px-6 py-6">
          <ScoreDisplay result={quizResult} quiz={quiz} />
        </div>
      </div>
    );
  }

  // Show quiz start screen
  if (!quizStarted) {
    return (
      <div className="min-h-screen bg-dark-bg text-white">
        <div className="bg-dark-card border-b border-dark-border">
          <div className="max-w-4xl mx-auto px-6 py-4">
            <button
              onClick={() => navigate('/quiz')}
              className="flex items-center gap-2 text-gray-400 hover:text-white transition-colors"
            >
              <ArrowLeft className="w-5 h-5" />
              <span>Back to Quizzes</span>
            </button>
          </div>
        </div>

        <div className="max-w-4xl mx-auto px-6 py-12">
          <div className="bg-gradient-to-br from-blue-600 to-purple-600 rounded-xl p-8 mb-8">
            <h1 className="text-3xl font-bold text-white mb-2">{quiz.title}</h1>
            <p className="text-gray-200">{quiz.description}</p>
          </div>

          <div className="bg-dark-card border border-dark-border rounded-xl p-8">
            <h2 className="text-2xl font-bold mb-6">Quiz Information</h2>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
              <div>
                <p className="text-gray-400 mb-1">Total Questions</p>
                <p className="text-2xl font-bold">{quiz.questions.length}</p>
              </div>
              
              {quiz.timeLimit && (
                <div>
                  <p className="text-gray-400 mb-1">Time Limit</p>
                  <p className="text-2xl font-bold">{quiz.timeLimit} minutes</p>
                </div>
              )}
              
              <div>
                <p className="text-gray-400 mb-1">Difficulty</p>
                <p className="text-2xl font-bold">{quiz.difficulty}</p>
              </div>
              
              <div>
                <p className="text-gray-400 mb-1">Max Reward</p>
                <p className="text-2xl font-bold text-accent-gold">
                  {quiz.questions.length * 2} CNE
                </p>
              </div>
            </div>

            <div className="bg-blue-500/10 border border-blue-500/30 rounded-lg p-4 mb-8">
              <h3 className="font-bold text-white mb-2">Instructions:</h3>
              <ul className="space-y-2 text-sm text-gray-300">
                <li>• Answer all questions to the best of your ability</li>
                <li>• You earn 2 CNE for each correct answer</li>
                {quiz.timeLimit && <li>• Complete the quiz within the time limit</li>}
                <li>• You can navigate between questions using the buttons</li>
                <li>• Review your answers before submitting</li>
              </ul>
            </div>

            <button
              onClick={handleStartQuiz}
              className="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white font-bold py-4 px-6 rounded-lg transition-all flex items-center justify-center gap-2"
            >
              <Play className="w-5 h-5" />
              Start Quiz
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Show quiz questions
  const currentQuestion = quiz.questions[currentQuestionIndex];
  const progress = ((currentQuestionIndex + 1) / quiz.questions.length) * 100;
  const allAnswered = answers.every(a => a !== null);

  return (
    <div className="min-h-screen bg-dark-bg text-white pb-20">
      {/* Header */}
      <div className="bg-dark-card border-b border-dark-border sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-bold">{quiz.title}</h2>
            {quiz.timeLimit && (
              <Timer
                duration={quiz.timeLimit * 60}
                onTimeUp={handleTimeUp}
                isActive={quizStarted && !quizResult}
              />
            )}
          </div>
          
          {/* Progress Bar */}
          <div className="w-full bg-dark-bg rounded-full h-2 overflow-hidden">
            <div
              className="bg-gradient-to-r from-blue-600 to-purple-600 h-full transition-all duration-300"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-6 py-6">
        <QuestionDisplay
          question={currentQuestion}
          questionNumber={currentQuestionIndex + 1}
          totalQuestions={quiz.questions.length}
          selectedAnswer={answers[currentQuestionIndex]}
          onSelectAnswer={handleSelectAnswer}
        />

        {/* Navigation Buttons */}
        <div className="mt-6 flex flex-col sm:flex-row gap-4">
          <button
            onClick={handlePreviousQuestion}
            disabled={currentQuestionIndex === 0}
            className="flex-1 bg-dark-card hover:bg-dark-border border border-dark-border text-white font-bold py-3 px-6 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Previous
          </button>

          {currentQuestionIndex < quiz.questions.length - 1 ? (
            <button
              onClick={handleNextQuestion}
              className="flex-1 bg-primary hover:bg-primary-light text-white font-bold py-3 px-6 rounded-lg transition-colors"
            >
              Next
            </button>
          ) : (
            <button
              onClick={handleSubmitQuiz}
              disabled={!allAnswered || submitting}
              className="flex-1 bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800 text-white font-bold py-3 px-6 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {submitting ? 'Submitting...' : 'Submit Quiz'}
            </button>
          )}
        </div>

        {/* Question Navigator */}
        <div className="mt-6 bg-dark-card border border-dark-border rounded-lg p-4">
          <p className="text-sm text-gray-400 mb-3">Question Navigator</p>
          <div className="grid grid-cols-5 sm:grid-cols-10 gap-2">
            {quiz.questions.map((_, index) => (
              <button
                key={index}
                onClick={() => setCurrentQuestionIndex(index)}
                className={`aspect-square rounded-lg font-bold text-sm transition-colors ${
                  index === currentQuestionIndex
                    ? 'bg-primary text-white'
                    : answers[index] !== null
                    ? 'bg-green-500/20 text-green-500 border border-green-500/30'
                    : 'bg-dark-bg text-gray-500 border border-dark-border hover:bg-dark-border'
                }`}
              >
                {index + 1}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default QuizPlayPage;
