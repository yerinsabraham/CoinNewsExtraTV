import { Play, Clock, Award } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const VideoCard = ({ video, watched = false }) => {
  const navigate = useNavigate();

  const formatDuration = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const handleClick = () => {
    navigate(`/videos/${video.id}`);
  };

  return (
    <div 
      onClick={handleClick}
      className="bg-dark-card rounded-lg overflow-hidden cursor-pointer transform transition-all duration-300 hover:scale-105 hover:shadow-xl border border-dark-border"
    >
      {/* Thumbnail */}
      <div className="relative aspect-video bg-gray-800">
        <img 
          src={video.thumbnail || `https://img.youtube.com/vi/${video.youtubeId}/maxresdefault.jpg`}
          alt={video.title}
          className="w-full h-full object-cover"
          onError={(e) => {
            e.target.src = `https://img.youtube.com/vi/${video.youtubeId}/hqdefault.jpg`;
          }}
        />
        
        {/* Play overlay */}
        <div className="absolute inset-0 bg-black bg-opacity-40 flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity duration-300">
          <div className="bg-primary rounded-full p-4">
            <Play className="w-8 h-8 text-white fill-white" />
          </div>
        </div>

        {/* Duration badge */}
        <div className="absolute bottom-2 right-2 bg-black bg-opacity-80 px-2 py-1 rounded text-xs font-semibold flex items-center gap-1">
          <Clock className="w-3 h-3" />
          {formatDuration(video.duration)}
        </div>

        {/* Watched badge */}
        {watched && (
          <div className="absolute top-2 right-2 bg-primary bg-opacity-90 px-2 py-1 rounded text-xs font-bold">
            WATCHED
          </div>
        )}
      </div>

      {/* Content */}
      <div className="p-4">
        <h3 className="font-bold text-white line-clamp-2 mb-2">
          {video.title}
        </h3>
        
        <p className="text-gray-400 text-sm line-clamp-2 mb-3">
          {video.description}
        </p>

        <div className="flex items-center justify-between">
          {/* Category */}
          <span className="text-xs bg-dark-bg px-2 py-1 rounded text-primary-light">
            {video.category}
          </span>

          {/* Reward badge */}
          {!watched && (
            <div className="flex items-center gap-1 text-accent-gold font-bold text-sm">
              <Award className="w-4 h-4" />
              +7 CNE
            </div>
          )}
        </div>

        {/* Views and date */}
        <div className="flex items-center gap-3 mt-3 text-xs text-gray-500">
          <span>{video.views?.toLocaleString() || 0} views</span>
          <span>•</span>
          <span>{video.uploadedAt ? new Date(video.uploadedAt.seconds * 1000).toLocaleDateString() : 'Recently'}</span>
        </div>
      </div>
    </div>
  );
};

export default VideoCard;
