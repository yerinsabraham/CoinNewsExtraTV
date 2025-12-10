import React from 'react';

const ContextSelector = ({ selectedContext, onContextChange, disabled }) => {
  const contexts = [
    { value: 'general', label: 'General Help', emoji: '💬' },
    { value: 'crypto_news', label: 'Crypto News', emoji: '📰' },
    { value: 'platform_help', label: 'Platform Support', emoji: '🆘' },
    { value: 'earnings_tips', label: 'Earnings Tips', emoji: '💡' }
  ];

  return (
    <div className="mb-4">
      <label className="block text-sm text-gray-400 mb-2">Chat Context:</label>
      <div className="flex flex-wrap gap-2">
        {contexts.map((context) => (
          <button
            key={context.value}
            onClick={() => onContextChange(context.value)}
            disabled={disabled}
            className={`
              px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200
              flex items-center gap-2
              ${selectedContext === context.value
                ? 'bg-purple-600 text-white shadow-lg shadow-purple-500/50'
                : 'bg-gray-800 text-gray-300 hover:bg-gray-700'
              }
              disabled:opacity-50 disabled:cursor-not-allowed
            `}
          >
            <span>{context.emoji}</span>
            <span>{context.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
};

export default ContextSelector;
