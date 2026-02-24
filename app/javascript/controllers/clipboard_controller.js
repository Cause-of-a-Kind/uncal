import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  copy() {
    const text = this.sourceTarget.textContent.trim()
    navigator.clipboard.writeText(text).then(() => {
      const original = this.buttonTarget.textContent
      this.buttonTarget.textContent = "Copied!"
      setTimeout(() => {
        this.buttonTarget.textContent = original
      }, 2000)
    })
  }
}
