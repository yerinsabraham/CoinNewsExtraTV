import { useState, useEffect } from 'react';
import { Clock } from 'lucide-react';

const Timer = ({ duration, onTimeUp, isActive = true }) => {
  const [timeLeft, setTimeLeft] = useState(duration);

  useEffect(() => {
    if (!isActive || timeLeft <= 0) {
      if (timeLeft <= 0) {
        onTimeUp();
      }
      return;
    }

    const interval = setInterval(() => {
      setTimeLeft(prev => {
        if (prev <= 1) {
          clearInterval(interval);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [isActive, timeLeft, onTimeUp]);

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const getColorClass = () => {
    const percentage = (timeLeft / duration) * 100;
    if (percentage > 50) return 'text-green-500';
    if (percentage > 20) return 'text-yellow-500';
    return 'text-red-500';
  };

  return (
    <div className="flex items-center gap-2 bg-dark-card px-4 py-2 rounded-lg border border-dark-border">
      <Clock className={`w-5 h-5 ${getColorClass()}`} />
      <span className={`font-bold text-xl ${getColorClass()}`}>
        {formatTime(timeLeft)}
      </span>
    </div>
  );
};

export default Timer;
