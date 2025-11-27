import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['source', 'hidden', 'button', 'status']

  copy () {
    const text = (this.hiddenTarget?.value ?? this.sourceTarget?.innerText ?? '').toString()
    if (!text) return
    navigator.clipboard.writeText(text).then(() => {
      if (this.buttonTarget) {
        const original = this.buttonTarget.innerText
        this.buttonTarget.innerText = 'Copied'
        this.statusTarget && (this.statusTarget.textContent = 'Copied to clipboard')
        setTimeout(() => {
          this.buttonTarget.innerText = original
          this.statusTarget && (this.statusTarget.textContent = '')
        }, 900)
      }
    }).catch(() => {})
  }
}
