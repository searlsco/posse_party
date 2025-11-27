import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['input']

  pasted (e) {
    const content = e.clipboardData?.getData('text')
    if (content && content.trim().match(/^\d{6}$/)) {
      this.inputTarget.value = content.trim()
      this.inputTarget.closest('form').requestSubmit()
    }
  }

  caret () {
    const shouldHideCaret = this.inputTarget.maxLength === this.inputTarget.selectionStart &&
      this.inputTarget.maxLength === this.inputTarget.selectionEnd

    this.inputTarget.classList.toggle('caret-transparent', shouldHideCaret)
    this.inputTarget.classList.toggle('caret-success', !shouldHideCaret)
  }
}
