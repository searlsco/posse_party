import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect () {
    const iframe = this.element.querySelector('iframe')
    if (!iframe) return

    iframe.addEventListener('load', () => {
      this.resizeIframe(iframe)
    })

    // Also try to resize immediately in case already loaded
    this.resizeIframe(iframe)
  }

  resizeIframe (iframe) {
    try {
      // For same-origin iframes, we can access the content
      const height = iframe.contentWindow.document.body.scrollHeight
      iframe.style.height = `${height}px`
    } catch (e) {
      // For cross-origin iframes, we can't access the content
      // Set a reasonable default height
      iframe.style.height = '600px'
    }
  }
}
