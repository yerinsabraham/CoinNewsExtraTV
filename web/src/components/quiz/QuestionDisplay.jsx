const QuestionDisplay = ({ question, questionNumber, totalQuestions, selectedAnswer, onSelectAnswer }) => {
  return (
    <div className="bg-dark-card rounded-lg p-6 border border-dark-border">
      {/* Question Header */}
      <div className="flex items-center justify-between mb-4">
        <span className="text-sm text-gray-400">
          Question {questionNumber} of {totalQuestions}
        </span>
        <span className="text-xs bg-primary/20 text-primary px-3 py-1 rounded-full font-semibold">
          2 CNE
        </span>
      </div>

      {/* Question Text */}
      <h3 className="text-xl font-bold text-white mb-6">
        {question.question}
      </h3>

      {/* Answer Options */}
      <div className="space-y-3">
        {question.options.map((option, index) => {
          const isSelected = selectedAnswer === option;
          
          return (
            <button
              key={index}
              onClick={() => onSelectAnswer(option)}
              className={`w-full text-left p-4 rounded-lg border-2 transition-all duration-200 ${
                isSelected
                  ? 'border-primary bg-primary/10 text-white'
                  : 'border-dark-border bg-dark-bg text-gray-300 hover:border-gray-500 hover:bg-dark-card'
              }`}
            >
              <div className="flex items-center gap-3">
                <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center flex-shrink-0 ${
                  isSelected ? 'border-primary bg-primary' : 'border-gray-500'
                }`}>
                  {isSelected && (
                    <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                  )}
                </div>
                <span className="font-medium">{option}</span>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
};

export default QuestionDisplay;
