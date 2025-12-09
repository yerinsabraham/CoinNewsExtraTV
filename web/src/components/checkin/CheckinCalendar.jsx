import React, { useState, useEffect } from 'react';
import { ChevronLeft, ChevronRight, CheckCircle2 } from 'lucide-react';

/**
 * CheckinCalendar Component
 * Displays monthly calendar with check-in status
 */
const CheckinCalendar = ({ checkins = {}, onMonthChange }) => {
  const [currentDate, setCurrentDate] = useState(new Date());
  
  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();
  
  // Notify parent when month changes
  useEffect(() => {
    if (onMonthChange) {
      onMonthChange(year, month);
    }
  }, [year, month, onMonthChange]);
  
  // Get first day of month and total days
  const firstDayOfMonth = new Date(year, month, 1);
  const lastDayOfMonth = new Date(year, month + 1, 0);
  const daysInMonth = lastDayOfMonth.getDate();
  const startingDayOfWeek = firstDayOfMonth.getDay(); // 0 = Sunday
  
  // Month names
  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  
  // Day names
  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  
  // Navigate months
  const goToPreviousMonth = () => {
    setCurrentDate(new Date(year, month - 1, 1));
  };
  
  const goToNextMonth = () => {
    const today = new Date();
    // Don't allow navigating beyond current month
    if (year < today.getFullYear() || (year === today.getFullYear() && month < today.getMonth())) {
      setCurrentDate(new Date(year, month + 1, 1));
    }
  };
  
  const goToToday = () => {
    setCurrentDate(new Date());
  };
  
  // Check if a date has a check-in
  const hasCheckin = (day) => {
    const dateKey = new Date(year, month, day).toISOString().split('T')[0];
    return checkins[dateKey] !== undefined;
  };
  
  // Get check-in data for a date
  const getCheckinData = (day) => {
    const dateKey = new Date(year, month, day).toISOString().split('T')[0];
    return checkins[dateKey];
  };
  
  // Check if date is today
  const isToday = (day) => {
    const today = new Date();
    return day === today.getDate() && 
           month === today.getMonth() && 
           year === today.getFullYear();
  };
  
  // Check if date is in the future
  const isFuture = (day) => {
    const date = new Date(year, month, day);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return date > today;
  };
  
  // Generate calendar days
  const calendarDays = [];
  
  // Empty cells before first day
  for (let i = 0; i < startingDayOfWeek; i++) {
    calendarDays.push(null);
  }
  
  // Days of the month
  for (let day = 1; day <= daysInMonth; day++) {
    calendarDays.push(day);
  }
  
  const today = new Date();
  const isCurrentMonth = year === today.getFullYear() && month === today.getMonth();
  const canGoNext = year < today.getFullYear() || (year === today.getFullYear() && month < today.getMonth());
  
  return (
    <div className="bg-dark-card rounded-lg p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <button
          onClick={goToPreviousMonth}
          className="p-2 hover:bg-dark-bg rounded-lg transition-colors"
        >
          <ChevronLeft className="w-5 h-5 text-white" />
        </button>
        
        <div className="text-center">
          <h3 className="text-xl font-bold text-white">
            {monthNames[month]} {year}
          </h3>
          {!isCurrentMonth && (
            <button
              onClick={goToToday}
              className="text-sm text-primary hover:text-primary/80 mt-1"
            >
              Go to Today
            </button>
          )}
        </div>
        
        <button
          onClick={goToNextMonth}
          disabled={!canGoNext}
          className={`p-2 rounded-lg transition-colors ${
            canGoNext 
              ? 'hover:bg-dark-bg' 
              : 'opacity-30 cursor-not-allowed'
          }`}
        >
          <ChevronRight className="w-5 h-5 text-white" />
        </button>
      </div>
      
      {/* Day names */}
      <div className="grid grid-cols-7 gap-2 mb-2">
        {dayNames.map((day) => (
          <div
            key={day}
            className="text-center text-sm font-semibold text-gray-400 py-2"
          >
            {day}
          </div>
        ))}
      </div>
      
      {/* Calendar grid */}
      <div className="grid grid-cols-7 gap-2">
        {calendarDays.map((day, index) => {
          if (day === null) {
            return <div key={`empty-${index}`} className="aspect-square" />;
          }
          
          const checkedIn = hasCheckin(day);
          const checkinData = getCheckinData(day);
          const today = isToday(day);
          const future = isFuture(day);
          
          return (
            <div
              key={day}
              className={`
                aspect-square rounded-lg flex flex-col items-center justify-center
                transition-all duration-200
                ${today 
                  ? 'ring-2 ring-primary' 
                  : ''
                }
                ${checkedIn 
                  ? 'bg-primary hover:bg-primary/80 cursor-pointer' 
                  : future
                    ? 'bg-dark-bg/30 cursor-not-allowed'
                    : 'bg-dark-bg hover:bg-dark-bg/80'
                }
              `}
            >
              <span className={`text-sm font-semibold mb-1 ${
                checkedIn ? 'text-white' : future ? 'text-gray-600' : 'text-gray-400'
              }`}>
                {day}
              </span>
              
              {checkedIn && (
                <div className="flex flex-col items-center">
                  <CheckCircle2 className="w-4 h-4 text-white mb-0.5" />
                  {checkinData?.streak && (
                    <span className="text-xs text-white/80">
                      {checkinData.streak}🔥
                    </span>
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>
      
      {/* Legend */}
      <div className="flex items-center justify-center gap-6 mt-6 text-sm">
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-primary rounded"></div>
          <span className="text-gray-400">Checked In</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-dark-bg rounded"></div>
          <span className="text-gray-400">Missed</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-dark-bg/30 rounded"></div>
          <span className="text-gray-400">Future</span>
        </div>
      </div>
    </div>
  );
};

export default CheckinCalendar;
