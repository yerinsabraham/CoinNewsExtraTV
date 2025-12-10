import React from 'react';
import { Sparkles } from 'lucide-react';

const SuggestedQuestions = ({ questions, onQuestionClick, disabled }) => {
  return (
    <div className="mb-4">
      <div className="flex items-center gap-2 mb-3">
        <Sparkles className="w-4 h-4 text-purple-400" />
        <span className="text-sm text-gray-400">Suggested questions:</span>
      </div>
      
      <div className="flex flex-wrap gap-2">
        {questions.map((question, index) => (
          <button
            key={index}
            onClick={() => onQuestionClick(question)}
            disabled={disabled}
            className="
              px-3 py-2 bg-gray-800 text-gray-300 rounded-lg text-sm
              hover:bg-gray-700 hover:text-white transition-all duration-200
              border border-gray-700 hover:border-purple-500
              disabled:opacity-50 disabled:cursor-not-allowed
            "
          >
            {question}
          </button>
        ))}
      </div>
    </div>
  );
};

export default SuggestedQuestions;
