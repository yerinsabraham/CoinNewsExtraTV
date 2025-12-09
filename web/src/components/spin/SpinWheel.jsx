import React, { useState, useRef } from 'react';
import { motion, useAnimation } from 'framer-motion';
import { Sparkles } from 'lucide-react';

/**
 * SpinWheel Component
 * Animated spinning wheel with reward segments
 */
const SpinWheel = ({ segments, onSpinComplete, disabled = false }) => {
  const [isSpinning, setIsSpinning] = useState(false);
  const controls = useAnimation();
  const wheelRef = useRef(null);
  
  const totalSegments = segments.length;
  const segmentAngle = 360 / totalSegments;
  
  const handleSpin = async () => {
    if (disabled || isSpinning) return;
    
    setIsSpinning(true);
    
    // Calculate random final rotation (3-5 full spins + random offset)
    const fullSpins = 3 + Math.random() * 2; // 3-5 full rotations
    const randomOffset = Math.random() * 360; // Random final position
    const totalRotation = fullSpins * 360 + randomOffset;
    
    // Animate the spin
    await controls.start({
      rotate: totalRotation,
      transition: {
        duration: 4,
        ease: [0.17, 0.67, 0.38, 0.96], // Custom easing for realistic spin
      }
    });
    
    // Calculate which segment was landed on
    const normalizedRotation = totalRotation % 360;
    const segmentIndex = Math.floor((360 - normalizedRotation + segmentAngle / 2) / segmentAngle) % totalSegments;
    const landedSegment = segments[segmentIndex];
    
    setIsSpinning(false);
    
    // Call completion callback
    if (onSpinComplete) {
      onSpinComplete(landedSegment);
    }
  };
  
  return (
    <div className="flex flex-col items-center gap-6">
      {/* Spin Button */}
      <button
        onClick={handleSpin}
        disabled={disabled || isSpinning}
        className={`
          px-8 py-4 rounded-full font-bold text-xl shadow-lg
          transition-all duration-300 transform
          flex items-center gap-3
          ${disabled || isSpinning
            ? 'bg-gray-400 cursor-not-allowed opacity-50'
            : 'bg-gradient-to-r from-primary to-green-600 text-white hover:scale-105 hover:shadow-xl'
          }
        `}
      >
        <Sparkles className={`w-6 h-6 ${isSpinning ? 'animate-spin' : ''}`} />
        {isSpinning ? 'Spinning...' : 'SPIN NOW'}
        <Sparkles className={`w-6 h-6 ${isSpinning ? 'animate-spin' : ''}`} />
      </button>
      
      {/* Wheel Container */}
      <div className="relative">
        {/* Pointer/Arrow at top */}
        <div className="absolute -top-8 left-1/2 transform -translate-x-1/2 z-20">
          <div className="w-0 h-0 border-l-[20px] border-l-transparent border-r-[20px] border-r-transparent border-t-[30px] border-t-red-500 drop-shadow-lg"></div>
        </div>
        
        {/* Wheel */}
        <motion.div
          ref={wheelRef}
          animate={controls}
          className="relative w-[400px] h-[400px] rounded-full shadow-2xl"
          style={{
            background: 'linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%)',
          }}
        >
          {/* Center circle */}
          <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-20 h-20 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full shadow-lg z-10 flex items-center justify-center">
            <Sparkles className="w-10 h-10 text-white" />
          </div>
          
          {/* Segments */}
          {segments.map((segment, index) => {
            const rotation = index * segmentAngle;
            
            return (
              <div
                key={index}
                className="absolute top-0 left-0 w-full h-full"
                style={{
                  transform: `rotate(${rotation}deg)`,
                  clipPath: `polygon(50% 50%, 50% 0%, ${50 + 50 * Math.sin((segmentAngle * Math.PI) / 180)}% ${50 - 50 * Math.cos((segmentAngle * Math.PI) / 180)}%)`,
                }}
              >
                <div
                  className="w-full h-full flex items-start justify-center pt-8"
                  style={{
                    background: segment.color,
                  }}
                >
                  <div
                    className="text-white font-bold text-lg drop-shadow-lg"
                    style={{
                      transform: `rotate(${segmentAngle / 2}deg)`,
                    }}
                  >
                    {segment.label}
                  </div>
                </div>
              </div>
            );
          })}
          
          {/* Outer ring */}
          <div className="absolute inset-0 rounded-full border-8 border-yellow-400 shadow-lg"></div>
        </motion.div>
      </div>
    </div>
  );
};

export default SpinWheel;
