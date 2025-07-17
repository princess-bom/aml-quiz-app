import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton"]

  connect() {
    // Enable submit button when a choice is selected
    this.updateSubmitButton()
  }

  selectChoice(event) {
    this.updateSubmitButton()
  }

  updateSubmitButton() {
    const selectedChoice = this.element.querySelector('input[name="answer"]:checked')
    this.submitButtonTarget.disabled = !selectedChoice
  }
}