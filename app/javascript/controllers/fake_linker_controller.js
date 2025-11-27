import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

// This is necessary for button-like links (e.g. tab bar) that are literally
// links to URLs but which we don't want to respond to long-press previews and
// touch-drags on mobile browsers
export default class extends Controller {
  static targets = ['link']

  connect () {
    this.openFakeLink = this.openFakeLink.bind(this)
    this.linkTargets.forEach(el => {
      el.addEventListener('click', this.openFakeLink)
    })
  }

  disconnect () {
    this.linkTargets.forEach(el => {
      el.removeEventListener('click', this.openFakeLink)
    })
  }

  openFakeLink (e) {
    e.preventDefault()
    Turbo.visit(e.currentTarget.dataset.linkPath)
  }
}
