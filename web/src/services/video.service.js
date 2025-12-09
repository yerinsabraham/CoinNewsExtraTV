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
 * Video Service
 * Handles all video-related operations including fetching videos,
 * tracking watch progress, and managing Watch2Earn rewards
 */

class VideoService {
  constructor() {
    this.videosCollection = 'videos';
    this.watchHistoryCollection = 'watchHistory';
    this.REWARD_AMOUNT = 7; // CNE reward per video
    this.COMPLETION_THRESHOLD = 0.8; // 80% watch time required
  }

  /**
   * Fetch all videos from Firestore
   * @param {Object} filters - Optional filters (category, featured, etc.)
   * @returns {Promise<Array>} Array of video objects
   */
  async getVideos(filters = {}) {
    try {
      let q = query(collection(db, this.videosCollection));

      // Apply filters
      if (filters.category) {
        q = query(q, where('category', '==', filters.category));
      }
      if (filters.featured) {
        q = query(q, where('featured', '==', true));
      }

      // Sort by upload date (newest first)
      q = query(q, orderBy('uploadedAt', 'desc'));

      if (filters.limit) {
        q = query(q, limit(filters.limit));
      }

      const snapshot = await getDocs(q);
      const videos = [];
      
      snapshot.forEach(doc => {
        videos.push({
          id: doc.id,
          ...doc.data()
        });
      });

      return videos;
    } catch (error) {
      console.error('Error fetching videos:', error);
      throw error;
    }
  }

  /**
   * Get a single video by ID
   * @param {string} videoId - Video document ID
   * @returns {Promise<Object>} Video object
   */
  async getVideoById(videoId) {
    try {
      const videoDoc = await getDoc(doc(db, this.videosCollection, videoId));
      
      if (!videoDoc.exists()) {
        throw new Error('Video not found');
      }

      return {
        id: videoDoc.id,
        ...videoDoc.data()
      };
    } catch (error) {
      console.error('Error fetching video:', error);
      throw error;
    }
  }

  /**
   * Get user's watch history
   * @param {string} userId - User ID
   * @returns {Promise<Array>} Array of watched video records
   */
  async getWatchHistory(userId) {
    try {
      const q = query(
        collection(db, this.watchHistoryCollection),
        where('userId', '==', userId),
        orderBy('watchedAt', 'desc')
      );

      const snapshot = await getDocs(q);
      const history = [];

      snapshot.forEach(doc => {
        history.push({
          id: doc.id,
          ...doc.data()
        });
      });

      return history;
    } catch (error) {
      console.error('Error fetching watch history:', error);
      throw error;
    }
  }

  /**
   * Check if user has already watched and earned reward for a video
   * @param {string} userId - User ID
   * @param {string} videoId - Video ID
   * @returns {Promise<Object|null>} Watch record or null
   */
  async checkWatchStatus(userId, videoId) {
    try {
      const watchId = `${userId}_${videoId}`;
      const watchDoc = await getDoc(
        doc(db, this.watchHistoryCollection, watchId)
      );

      if (watchDoc.exists()) {
        return {
          id: watchDoc.id,
          ...watchDoc.data()
        };
      }

      return null;
    } catch (error) {
      console.error('Error checking watch status:', error);
      throw error;
    }
  }

  /**
   * Track video watch progress and award CNE if completed
   * @param {string} userId - User ID
   * @param {string} videoId - Video ID
   * @param {number} watchedDuration - Seconds watched
   * @param {number} totalDuration - Total video duration in seconds
   * @returns {Promise<Object>} Result with reward info
   */
  async trackWatch(userId, videoId, watchedDuration, totalDuration) {
    try {
      const watchId = `${userId}_${videoId}`;
      const completion = watchedDuration / totalDuration;

      // Check if already watched and rewarded
      const existingWatch = await this.checkWatchStatus(userId, videoId);
      
      if (existingWatch && existingWatch.rewarded) {
        return {
          success: false,
          alreadyRewarded: true,
          message: 'You have already earned rewards for this video'
        };
      }

      // Check if completion threshold is met
      const shouldReward = completion >= this.COMPLETION_THRESHOLD;

      // Update or create watch record
      const watchData = {
        userId,
        videoId,
        watchedDuration,
        totalDuration,
        completion,
        rewarded: shouldReward,
        watchedAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      };

      await setDoc(
        doc(db, this.watchHistoryCollection, watchId),
        watchData,
        { merge: true }
      );

      // Award CNE if threshold met
      if (shouldReward) {
        await this.awardVideoReward(userId, videoId);
        
        return {
          success: true,
          rewarded: true,
          amount: this.REWARD_AMOUNT,
          message: `Congratulations! You earned ${this.REWARD_AMOUNT} CNE!`
        };
      }

      return {
        success: true,
        rewarded: false,
        completion: Math.round(completion * 100),
        message: `Watch ${Math.round(this.COMPLETION_THRESHOLD * 100)}% to earn ${this.REWARD_AMOUNT} CNE`
      };
    } catch (error) {
      console.error('Error tracking watch:', error);
      throw error;
    }
  }

  /**
   * Award CNE reward for watching video
   * @param {string} userId - User ID
   * @param {string} videoId - Video ID
   * @private
   */
  async awardVideoReward(userId, videoId) {
    try {
      const userRef = doc(db, 'users', userId);

      // Update user's CNE balance and watch2earn earnings
      await updateDoc(userRef, {
        'balance.totalBalance': increment(this.REWARD_AMOUNT),
        'balance.unlockedBalance': increment(this.REWARD_AMOUNT),
        'earnings.watch2Earn': increment(this.REWARD_AMOUNT),
        'stats.videosWatched': increment(1),
        updatedAt: serverTimestamp()
      });

      // Log the reward transaction
      await this.logRewardTransaction(userId, videoId, this.REWARD_AMOUNT);
    } catch (error) {
      console.error('Error awarding video reward:', error);
      throw error;
    }
  }

  /**
   * Log reward transaction for audit trail
   * @param {string} userId - User ID
   * @param {string} videoId - Video ID
   * @param {number} amount - Reward amount
   * @private
   */
  async logRewardTransaction(userId, videoId, amount) {
    try {
      const transactionData = {
        userId,
        type: 'watch2earn',
        videoId,
        amount,
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
   * Get video categories
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
      'News',
      'Tutorials',
      'Market Analysis'
    ];
  }

  /**
   * Extract YouTube video ID from URL
   * @param {string} url - YouTube URL
   * @returns {string} Video ID
   */
  extractYouTubeId(url) {
    const patterns = [
      /(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\n?#]+)/,
      /youtube\.com\/embed\/([^&\n?#]+)/
    ];

    for (const pattern of patterns) {
      const match = url.match(pattern);
      if (match) return match[1];
    }

    return url; // Assume it's already an ID
  }
}

export default new VideoService();
