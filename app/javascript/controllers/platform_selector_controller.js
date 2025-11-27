import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    url: String,
    turboFrameId: String,
    overridesUrl: String,
    overridesTurboFrameId: String
  }

  updateCredentialFields () {
    const platformTag = this.element.value
    const frame = document.getElementById(this.turboFrameIdValue)

    if (!frame) return

    frame.src = this.buildUrl(this.urlValue, platformTag)
  }

  updateOverrideFields () {
    const platformTag = this.element.value
    const frame = document.getElementById(this.overridesTurboFrameIdValue)

    if (!frame) return

    if (platformTag) {
      frame.src = this.buildUrl(this.overridesUrlValue, platformTag)
    } else {
      frame.removeAttribute('src')
      frame.innerHTML = ''
    }
  }

  buildUrl (baseUrl, platformTag) {
    const url = new URL(baseUrl, window.location.origin)

    if (platformTag) {
      url.searchParams.set('platform_tag', platformTag)
    } else {
      url.searchParams.delete('platform_tag')
    }

    return url.toString()
  }
}
