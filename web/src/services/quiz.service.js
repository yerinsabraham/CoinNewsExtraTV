import { db } from './firebase';
import { 
  collection, 
  query, 
  getDocs, 
  doc, 
  getDoc,
  setDoc,
  updateDoc,
  increment,
  serverTimestamp,
  where,
  orderBy,
  limit
} from 'firebase/firestore';

/**
 * Quiz Service
 * Handles all quiz-related operations including fetching quizzes,
 * tracking answers, calculating scores, and managing quiz rewards
 */

class QuizService {
  constructor() {
    this.quizzesCollection = 'quizzes';
    this.quizAttemptsCollection = 'quizAttempts';
    this.REWARD_PER_CORRECT = 2; // CNE reward per correct answer
  }

  /**
   * Fetch all available quizzes
   * @param {Object} filters - Optional filters (category, difficulty, etc.)
   * @returns {Promise<Array>} Array of quiz objects
   */
  async getQuizzes(filters = {}) {
    try {
      let q = query(collection(db, this.quizzesCollection));

      // Apply filters
      if (filters.category) {
        q = query(q, where('category', '==', filters.category));
      }
      if (filters.difficulty) {
        q = query(q, where('difficulty', '==', filters.difficulty));
      }
      if (filters.active !== undefined) {
        q = query(q, where('active', '==', filters.active));
      }

      // Sort by created date (newest first)
      q = query(q, orderBy('createdAt', 'desc'));

      if (filters.limit) {
        q = query(q, limit(filters.limit));
      }

      const snapshot = await getDocs(q);
      const quizzes = [];
      
      snapshot.forEach(doc => {
        quizzes.push({
          id: doc.id,
          ...doc.data()
        });
      });

      return quizzes;
    } catch (error) {
      console.error('Error fetching quizzes:', error);
      throw error;
    }
  }

  /**
   * Get a single quiz with questions
   * @param {string} quizId - Quiz document ID
   * @returns {Promise<Object>} Quiz object with questions
   */
  async getQuizById(quizId) {
    try {
      const quizDoc = await getDoc(doc(db, this.quizzesCollection, quizId));
      
      if (!quizDoc.exists()) {
        throw new Error('Quiz not found');
      }

      const quizData = {
        id: quizDoc.id,
        ...quizDoc.data()
      };

      // Fetch questions for this quiz
      const questionsQuery = query(
        collection(db, this.quizzesCollection, quizId, 'questions'),
        orderBy('order', 'asc')
      );
      
      const questionsSnapshot = await getDocs(questionsQuery);
      const questions = [];
      
      questionsSnapshot.forEach(doc => {
        questions.push({
          id: doc.id,
          ...doc.data()
        });
      });

      quizData.questions = questions;
      return quizData;
    } catch (error) {
      console.error('Error fetching quiz:', error);
      throw error;
    }
  }

  /**
   * Get user's quiz attempts
   * @param {string} userId - User ID
   * @returns {Promise<Array>} Array of quiz attempts
   */
  async getUserAttempts(userId) {
    try {
      const q = query(
        collection(db, this.quizAttemptsCollection),
        where('userId', '==', userId),
        orderBy('completedAt', 'desc')
      );

      const snapshot = await getDocs(q);
      const attempts = [];

      snapshot.forEach(doc => {
        attempts.push({
          id: doc.id,
          ...doc.data()
        });
      });

      return attempts;
    } catch (error) {
      console.error('Error fetching quiz attempts:', error);
      throw error;
    }
  }

  /**
   * Check if user has completed a quiz today
   * @param {string} userId - User ID
   * @param {string} quizId - Quiz ID
   * @returns {Promise<boolean>} True if completed today
   */
  async hasCompletedToday(userId, quizId) {
    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const q = query(
        collection(db, this.quizAttemptsCollection),
        where('userId', '==', userId),
        where('quizId', '==', quizId),
        where('completedAt', '>=', today)
      );

      const snapshot = await getDocs(q);
      return !snapshot.empty;
    } catch (error) {
      console.error('Error checking quiz completion:', error);
      return false;
    }
  }

  /**
   * Submit quiz answers and calculate score
   * @param {string} userId - User ID
   * @param {string} quizId - Quiz ID
   * @param {Array} answers - User's answers
   * @param {Array} questions - Quiz questions
   * @param {number} timeTaken - Time taken in seconds
   * @returns {Promise<Object>} Result with score and rewards
   */
  async submitQuiz(userId, quizId, answers, questions, timeTaken) {
    try {
      // Calculate score
      let correctCount = 0;
      const results = [];

      questions.forEach((question, index) => {
        const userAnswer = answers[index];
        const isCorrect = userAnswer === question.correctAnswer;
        
        if (isCorrect) {
          correctCount++;
        }

        results.push({
          questionId: question.id,
          question: question.question,
          userAnswer,
          correctAnswer: question.correctAnswer,
          isCorrect
        });
      });

      const totalQuestions = questions.length;
      const percentage = Math.round((correctCount / totalQuestions) * 100);
      const cneEarned = correctCount * this.REWARD_PER_CORRECT;

      // Save attempt to Firestore
      const attemptData = {
        userId,
        quizId,
        correctCount,
        totalQuestions,
        percentage,
        cneEarned,
        timeTaken,
        results,
        completedAt: serverTimestamp()
      };

      const attemptRef = doc(collection(db, this.quizAttemptsCollection));
      await setDoc(attemptRef, attemptData);

      // Award CNE if user got correct answers
      if (cneEarned > 0) {
        await this.awardQuizReward(userId, quizId, cneEarned, correctCount);
      }

      return {
        success: true,
        correctCount,
        totalQuestions,
        percentage,
        cneEarned,
        timeTaken,
        results,
        attemptId: attemptRef.id
      };
    } catch (error) {
      console.error('Error submitting quiz:', error);
      throw error;
    }
  }

  /**
   * Award CNE reward for quiz completion
   * @param {string} userId - User ID
   * @param {string} quizId - Quiz ID
   * @param {number} amount - CNE amount to award
   * @param {number} correctCount - Number of correct answers
   * @private
   */
  async awardQuizReward(userId, quizId, amount, correctCount) {
    try {
      const userRef = doc(db, 'users', userId);

      // Update user's CNE balance and quiz earnings
      await updateDoc(userRef, {
        'balance.totalBalance': increment(amount),
        'balance.unlockedBalance': increment(amount),
        'earnings.quiz': increment(amount),
        'stats.quizzesTaken': increment(1),
        'stats.quizCorrectAnswers': increment(correctCount),
        updatedAt: serverTimestamp()
      });

      // Log the reward transaction
      await this.logRewardTransaction(userId, quizId, amount, correctCount);
    } catch (error) {
      console.error('Error awarding quiz reward:', error);
      throw error;
    }
  }

  /**
   * Log reward transaction for audit trail
   * @param {string} userId - User ID
   * @param {string} quizId - Quiz ID
   * @param {number} amount - Reward amount
   * @param {number} correctCount - Number of correct answers
   * @private
   */
  async logRewardTransaction(userId, quizId, amount, correctCount) {
    try {
      const transactionData = {
        userId,
        type: 'quiz',
        quizId,
        amount,
        correctCount,
        timestamp: serverTimestamp()
      };

      await setDoc(
        doc(collection(db, 'transactions')),
        transactionData
      );
    } catch (error) {
      console.error('Error logging transaction:', error);
      // Don't throw - transaction logging is not critical
    }
  }

  /**
   * Get quiz categories
   * @returns {Array<string>} List of categories
   */
  getCategories() {
    return [
      'All',
      'Bitcoin',
      'Ethereum',
      'Altcoins',
      'DeFi',
      'NFTs',
      'Trading',
      'Blockchain',
      'Security',
      'General Knowledge'
    ];
  }

  /**
   * Get quiz difficulties
   * @returns {Array<string>} List of difficulties
   */
  getDifficulties() {
    return ['Easy', 'Medium', 'Hard'];
  }

  /**
   * Get user quiz statistics
   * @param {string} userId - User ID
   * @returns {Promise<Object>} User quiz stats
   */
  async getUserStats(userId) {
    try {
      const attempts = await this.getUserAttempts(userId);
      
      const stats = {
        totalAttempts: attempts.length,
        totalCorrect: 0,
        totalQuestions: 0,
        totalEarned: 0,
        averageScore: 0,
        bestScore: 0
      };

      attempts.forEach(attempt => {
        stats.totalCorrect += attempt.correctCount || 0;
        stats.totalQuestions += attempt.totalQuestions || 0;
        stats.totalEarned += attempt.cneEarned || 0;
        
        if (attempt.percentage > stats.bestScore) {
          stats.bestScore = attempt.percentage;
        }
      });

      if (stats.totalAttempts > 0) {
        stats.averageScore = Math.round(
          (stats.totalCorrect / stats.totalQuestions) * 100
        );
      }

      return stats;
    } catch (error) {
      console.error('Error getting user stats:', error);
      return {
        totalAttempts: 0,
        totalCorrect: 0,
        totalQuestions: 0,
        totalEarned: 0,
        averageScore: 0,
        bestScore: 0
      };
    }
  }
}

export default new QuizService();
