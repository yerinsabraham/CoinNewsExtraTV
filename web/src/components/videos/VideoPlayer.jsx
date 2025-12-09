import { useState, useEffect, useRef } from 'react';
import ReactPlayer from 'react-player';
import { Award, CheckCircle, Loader } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import videoService from '../../services/video.service';
import { useBalanceStore } from '../../stores/balanceStore';
import toast from 'react-hot-toast';

const VideoPlayer = ({ video }) => {
  const { user } = useAuth();
  const addReward = useBalanceStore(state => state.addReward);
  const [playing, setPlaying] = useState(false);
  const [watchedSeconds, setWatchedSeconds] = useState(0);
  const [isRewarded, setIsRewarded] = useState(false);
  const [isChecking, setIsChecking] = useState(true);
  const [completion, setCompletion] = useState(0);
  const playerRef = useRef(null);
  const trackingIntervalRef = useRef(null);

  // Check if video was already watched
  useEffect(() => {
    const checkWatchStatus = async () => {
      if (!user || !video) return;
      
      try {
        setIsChecking(true);
        const watchStatus = await videoService.checkWatchStatus(user.uid, video.id);
        
        if (watchStatus && watchStatus.rewarded) {
          setIsRewarded(true);
          setCompletion(100);
        }
      } catch (error) {
        console.error('Error checking watch status:', error);
      } finally {
        setIsChecking(false);
      }
    };

    checkWatchStatus();
  }, [user, video]);

  // Track watch progress every 10 seconds
  useEffect(() => {
    if (playing && !isRewarded && user) {
      trackingIntervalRef.current = setInterval(() => {
        const currentTime = playerRef.current?.getCurrentTime() || 0;
        const duration = playerRef.current?.getDuration() || video.duration;
        
        if (duration > 0) {
          const currentCompletion = (currentTime / duration) * 100;
          setCompletion(currentCompletion);
          
          // Track progress in Firestore
          handleProgressUpdate(currentTime, duration);
        }
      }, 10000); // Every 10 seconds
    } else {
      if (trackingIntervalRef.current) {
        clearInterval(trackingIntervalRef.current);
      }
    }

    return () => {
      if (trackingIntervalRef.current) {
        clearInterval(trackingIntervalRef.current);
      }
    };
  }, [playing, isRewarded, user]);

  const handleProgressUpdate = async (currentTime, duration) => {
    if (!user || !video || isRewarded) return;

    try {
      const result = await videoService.trackWatch(
        user.uid,
        video.id,
        Math.floor(currentTime),
        Math.floor(duration)
      );

      if (result.rewarded) {
        setIsRewarded(true);
        setCompletion(100);
        addReward(7, 'watch2earn');
        
        toast.success(
          <div className="flex items-center gap-2">
            <Award className="w-5 h-5 text-accent-gold" />
            <span>Earned 7 CNE for watching!</span>
          </div>,
          { duration: 5000 }
        );
      }
    } catch (error) {
      console.error('Error tracking progress:', error);
    }
  };

  const handleProgress = (state) => {
    setWatchedSeconds(state.playedSeconds);
  };

  const handleReady = () => {
    console.log('Video ready to play');
  };

  const handleEnded = () => {
    // Final tracking when video ends
    if (playerRef.current && !isRewarded) {
      const duration = playerRef.current.getDuration();
      handleProgressUpdate(duration, duration);
    }
  };

  if (isChecking) {
    return (
      <div className="w-full aspect-video bg-dark-card rounded-lg flex items-center justify-center">
        <Loader className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="relative">
      {/* Video Player */}
      <div className="relative aspect-video bg-black rounded-lg overflow-hidden">
        <ReactPlayer
          ref={playerRef}
          url={`https://www.youtube.com/watch?v=${video.youtubeId}`}
          width="100%"
          height="100%"
          playing={playing}
          controls={true}
          onPlay={() => setPlaying(true)}
          onPause={() => setPlaying(false)}
          onProgress={handleProgress}
          onReady={handleReady}
          onEnded={handleEnded}
          config={{
            youtube: {
              playerVars: {
                modestbranding: 1,
                rel: 0,
                showinfo: 0
              }
            }
          }}
        />
      </div>

      {/* Progress and Reward Info */}
      <div className="mt-4 bg-dark-card rounded-lg p-4 border border-dark-border">
        {isRewarded ? (
          <div className="flex items-center gap-3 text-primary">
            <CheckCircle className="w-6 h-6" />
            <div>
              <p className="font-bold">Video Completed!</p>
              <p className="text-sm text-gray-400">You earned 7 CNE for watching this video</p>
            </div>
          </div>
        ) : (
          <div>
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <Award className="w-5 h-5 text-accent-gold" />
                <span className="font-bold text-white">Watch to Earn 7 CNE</span>
              </div>
              <span className="text-sm text-gray-400">
                {Math.round(completion)}% watched
              </span>
            </div>
            
            {/* Progress bar */}
            <div className="w-full bg-dark-bg rounded-full h-2 overflow-hidden">
              <div 
                className="bg-gradient-to-r from-primary to-primary-light h-full transition-all duration-300"
                style={{ width: `${completion}%` }}
              />
            </div>
            
            <p className="text-xs text-gray-500 mt-2">
              Watch at least 80% of the video to earn your reward
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default VideoPlayer;
