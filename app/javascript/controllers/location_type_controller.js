import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["locationField", "meetHint"]

  connect() {
    this.toggle()
  }

  change() {
    this.toggle()
  }

  toggle() {
    const selected = this.element.querySelector("input[type=radio]:checked")?.value
    const isGoogleMeet = selected === "google_meet"

    this.locationFieldTarget.classList.toggle("hidden", isGoogleMeet)
    this.meetHintTarget.classList.toggle("hidden", !isGoogleMeet)
  }
}
