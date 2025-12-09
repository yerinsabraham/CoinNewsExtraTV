import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Calendar, Eye, Tag, Loader } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import videoService from '../../services/video.service';
import VideoPlayer from '../../components/videos/VideoPlayer';
import toast from 'react-hot-toast';

const VideoDetailPage = () => {
  const { videoId } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [video, setVideo] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadVideo();
  }, [videoId]);

  const loadVideo = async () => {
    try {
      setLoading(true);
      const videoData = await videoService.getVideoById(videoId);
      setVideo(videoData);
    } catch (error) {
      console.error('Error loading video:', error);
      toast.error('Failed to load video');
      navigate('/videos');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <Loader className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!video) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <div className="text-center">
          <p className="text-gray-400 text-lg mb-4">Video not found</p>
          <button
            onClick={() => navigate('/videos')}
            className="text-primary hover:underline"
          >
            Back to Videos
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-dark-bg text-white pb-20">
      {/* Back Button */}
      <div className="bg-dark-card border-b border-dark-border">
        <div className="max-w-6xl mx-auto px-6 py-4">
          <button
            onClick={() => navigate('/videos')}
            className="flex items-center gap-2 text-gray-400 hover:text-white transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            <span>Back to Videos</span>
          </button>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-6 py-6">
        {/* Video Player */}
        <VideoPlayer video={video} />

        {/* Video Info */}
        <div className="mt-6">
          <h1 className="text-2xl md:text-3xl font-bold mb-4">{video.title}</h1>

          {/* Meta Info */}
          <div className="flex flex-wrap items-center gap-4 text-sm text-gray-400 mb-6">
            <div className="flex items-center gap-2">
              <Eye className="w-4 h-4" />
              <span>{video.views?.toLocaleString() || 0} views</span>
            </div>
            
            <div className="flex items-center gap-2">
              <Calendar className="w-4 h-4" />
              <span>
                {video.uploadedAt 
                  ? new Date(video.uploadedAt.seconds * 1000).toLocaleDateString('en-US', {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric'
                    })
                  : 'Recently uploaded'
                }
              </span>
            </div>

            <div className="flex items-center gap-2">
              <Tag className="w-4 h-4" />
              <span className="bg-primary bg-opacity-20 text-primary px-2 py-1 rounded">
                {video.category}
              </span>
            </div>
          </div>

          {/* Description */}
          {video.description && (
            <div className="bg-dark-card rounded-lg p-6 border border-dark-border">
              <h2 className="font-bold text-lg mb-3">About this video</h2>
              <p className="text-gray-300 whitespace-pre-wrap leading-relaxed">
                {video.description}
              </p>
            </div>
          )}

          {/* Tags */}
          {video.tags && video.tags.length > 0 && (
            <div className="mt-6">
              <h3 className="font-semibold mb-3">Tags</h3>
              <div className="flex flex-wrap gap-2">
                {video.tags.map((tag, index) => (
                  <span
                    key={index}
                    className="bg-dark-card border border-dark-border px-3 py-1 rounded-full text-sm text-gray-400"
                  >
                    #{tag}
                  </span>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default VideoDetailPage;
