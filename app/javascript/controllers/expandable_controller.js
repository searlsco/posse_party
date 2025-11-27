import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['content', 'button']
  static values = {
    maxHeight: { type: Number, default: 200 },
    expanded: { type: Boolean, default: false }
  }

  connect () {
    this.checkHeight()
  }

  checkHeight () {
    const contentHeight = this.contentTarget.scrollHeight
    if (contentHeight > this.maxHeightValue) {
      this.element.classList.add('expandable')
      this.contentTarget.style.maxHeight = `${this.maxHeightValue}px`
      this.contentTarget.classList.add('overflow-hidden', 'relative')
      this.createGradient()
      this.buttonTarget.classList.remove('hidden')
    } else {
      this.buttonTarget.classList.add('hidden')
    }
  }

  createGradient () {
    if (!this.expandedValue) {
      const gradient = document.createElement('div')
      gradient.className = 'absolute bottom-0 left-0 right-0 h-16 bg-gradient-to-t from-secondary to-transparent pointer-events-none'
      gradient.setAttribute('data-expandable-gradient', '')
      this.contentTarget.appendChild(gradient)
    }
  }

  toggle () {
    this.expandedValue = !this.expandedValue

    if (this.expandedValue) {
      this.contentTarget.style.maxHeight = 'none'
      this.contentTarget.classList.add('transition-all', 'duration-500')
      this.buttonTarget.textContent = 'Show less'

      // Remove gradient
      const gradient = this.contentTarget.querySelector('[data-expandable-gradient]')
      if (gradient) gradient.remove()
    } else {
      this.contentTarget.style.maxHeight = `${this.maxHeightValue}px`
      this.buttonTarget.textContent = 'Show more'
      this.createGradient()
    }
  }
}
