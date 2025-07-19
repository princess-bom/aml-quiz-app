import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="quiz-answer"
export default class extends Controller {
  static targets = ["form", "submitButton", "options"]
  
  connect() {
    console.log("Quiz answer controller connected")
  }
  
  selectAnswer(event) {
    const option = event.currentTarget
    const answer = option.dataset.answer
    
    // Remove selected class from all options
    this.optionsTargets.forEach(opt => opt.classList.remove('selected'))
    
    // Add selected class to clicked option
    option.classList.add('selected')
    
    // Update radio button
    const radio = this.formTarget.querySelector(`input[value="${answer}"]`)
    if (radio) {
      radio.checked = true
    }
    
    // Enable submit button
    this.submitButtonTarget.disabled = false
  }
  
  async submitAnswer(event) {
    event.preventDefault()
    
    const form = this.formTarget
    const selectedAnswer = form.querySelector('input[name="selected_answer"]:checked')
    
    if (!selectedAnswer) {
      alert('답안을 선택해주세요.')
      return
    }
    
    // Disable submit button and show loading state
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = '제출 중...'
    
    try {
      const response = await fetch(form.action, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          question_id: form.dataset.questionId,
          selected_answer: selectedAnswer.value
        })
      })
      
      if (response.ok) {
        const result = await response.json()
        
        // Show result feedback
        this.showResult(result)
        
        // After 2 seconds, move to next question or show results
        setTimeout(() => {
          if (result.progress.current_question <= result.progress.total_questions) {
            window.location.reload()
          } else {
            // Quiz completed, redirect to complete action
            const sessionId = form.dataset.sessionId
            window.location.href = `/firebase_quiz/${sessionId}/complete`
          }
        }, 2000)
      } else {
        throw new Error('Failed to submit answer')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('답안 제출에 실패했습니다. 다시 시도해주세요.')
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.textContent = '답안 제출'
    }
  }
  
  showResult(result) {
    const selectedOption = this.optionsTargets.find(opt => 
      opt.dataset.answer === result.selected_answer
    )
    
    if (result.is_correct) {
      selectedOption.classList.add('correct')
      this.showFeedback(selectedOption, '✓ 정답', 'correct')
    } else {
      selectedOption.classList.add('wrong')
      this.showFeedback(selectedOption, '✗ 오답', 'wrong')
      
      // Show correct answer
      const correctOption = this.optionsTargets.find(opt => 
        opt.dataset.answer === result.correct_answer
      )
      if (correctOption) {
        correctOption.classList.add('correct')
        this.showFeedback(correctOption, '✓ 정답', 'correct')
      }
    }
    
    // Show explanation if available
    if (result.explanation) {
      this.showExplanation(result.explanation)
    }
    
    // Disable all options
    this.optionsTargets.forEach(opt => {
      opt.style.pointerEvents = 'none'
      opt.style.cursor = 'default'
    })
  }
  
  showFeedback(option, text, type) {
    const feedback = document.createElement('span')
    feedback.className = 'quiz-answer-feedback'
    feedback.textContent = text
    option.appendChild(feedback)
  }
  
  showExplanation(explanation) {
    const explanationDiv = document.createElement('div')
    explanationDiv.className = 'quiz-explanation'
    explanationDiv.innerHTML = `
      <h4 class="quiz-explanation-title">💡 해설</h4>
      <div class="quiz-explanation-content">
        ${explanation.correct_reason}
        ${explanation.key_point ? `
          <div class="quiz-explanation-keypoint">
            <strong>핵심 포인트:</strong> ${explanation.key_point}
          </div>
        ` : ''}
        ${explanation.reference ? `
          <div class="quiz-explanation-reference">
            <strong>참고:</strong> ${explanation.reference}
          </div>
        ` : ''}
      </div>
    `
    
    this.formTarget.parentElement.appendChild(explanationDiv)
  }
}