import { Controller } from "@hotwired/stimulus"

// Cycles through panels (TV mode): shows one target at a time.
export default class extends Controller {
  static targets = ["panel"]
  static values = { interval: { type: Number, default: 12 } }

  connect() {
    this.index = 0
    this.show()
    if (this.panelTargets.length > 1) {
      this.timer = setInterval(() => this.next(), this.intervalValue * 1000)
    }
  }

  disconnect() {
    clearInterval(this.timer)
  }

  next() {
    this.index = (this.index + 1) % this.panelTargets.length
    this.show()
  }

  show() {
    this.panelTargets.forEach((panel, i) => panel.classList.toggle("hidden", i !== this.index))
  }
}
