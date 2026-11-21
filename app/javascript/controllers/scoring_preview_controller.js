import { Controller } from "@hotwired/stimulus"

// Refreshes the scoring preview on the event form when a scoring setting or
// the team mode changes, by submitting the form to the preview endpoint
// (the "Update preview" button) into its Turbo Frame. Nothing is saved.
export default class extends Controller {
  static targets = ["button"]

  refresh(event) {
    const name = event.target.name || ""
    if (!this.hasButtonTarget || !(name.startsWith("event[scoring]") || name === "event[team_mode]")) return

    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(this.buttonTarget), 200)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
