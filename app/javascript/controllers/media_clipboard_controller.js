import { Controller } from '@hotwired/stimulus'

// Copies an image to the clipboard so it can be pasted straight into a platform's composer
export default class extends Controller {
  static values = { url: String }
  static targets = ['button']

  copy () {
    const original = this.buttonTarget.innerText
    // Handing ClipboardItem a promise keeps the write inside the click, which Safari requires
    const png = window.fetch(this.urlValue).then((response) => {
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      return response.blob()
    })
    navigator.clipboard.write([new window.ClipboardItem({ 'image/png': png })])
      .then(() => this.flash('Copied! Now paste it into the composer', original))
      .catch(() => this.flash('Copy failed (try dragging the image instead)', original))
  }

  flash (message, original) {
    this.buttonTarget.innerText = message
    setTimeout(() => { this.buttonTarget.innerText = original }, 2500)
  }
}
