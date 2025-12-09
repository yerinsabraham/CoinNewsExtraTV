import VideoCard from './VideoCard';

const VideoGrid = ({ videos, watchedVideos = [] }) => {
  if (!videos || videos.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-400 text-lg">No videos found</p>
        <p className="text-gray-500 text-sm mt-2">Check back later for new content!</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {videos.map(video => (
        <VideoCard 
          key={video.id} 
          video={video}
          watched={watchedVideos.includes(video.id)}
        />
      ))}
    </div>
  );
};

export default VideoGrid;
