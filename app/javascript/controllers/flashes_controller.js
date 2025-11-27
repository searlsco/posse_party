import { Controller } from '@hotwired/stimulus'

// Scrolls the flashes container into view whenever its contents change.
export default class extends Controller {
  connect () {
    this.scrollScheduled = false
    // Scroll shortly after connect in case HTML rendered before controller init
    this.scheduleScrollIfPresent()

    this.observer = new window.MutationObserver(() => this.scheduleScrollIfPresent())
    // Observe added/removed nodes, text changes, and attribute tweaks that
    // commonly occur during Turbo Stream updates (e.g., class/hidden toggles).
    this.observer.observe(this.element, {
      childList: true,
      characterData: true,
      attributes: true,
      attributeFilter: ['hidden', 'class', 'style', 'aria-hidden'],
      subtree: true
    })
  }

  disconnect () {
    this.observer && this.observer.disconnect()
  }

  scrollIfPresent () {
    const hasContent = this.element.textContent.trim().length > 0
    if (!hasContent) return

    // If already in view, avoid a redundant scroll
    const rect = this.element.getBoundingClientRect()
    const inView = rect.top >= 0 && rect.bottom <= window.innerHeight
    if (!inView) this.element.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }

  // Defer scrolling until after the DOM settles so that rapid Turbo Stream
  // mutations (like user deletion that also re-renders lists) coalesce.
  scheduleScrollIfPresent () {
    if (this.scrollScheduled) return
    this.scrollScheduled = true
    window.requestAnimationFrame(() => {
      window.requestAnimationFrame(() => {
        this.scrollScheduled = false
        this.scrollIfPresent()
      })
    })
  }
}
