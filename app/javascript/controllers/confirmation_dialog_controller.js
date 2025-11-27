import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['dialog', 'input', 'submit']

  connect () {
    this.reset()
  }

  open (event) {
    event.preventDefault()
    this.dialogTarget.showModal()
    this.focusInput()
  }

  close (event) {
    if (event) event.preventDefault()
    this.dialogTarget.close()
  }

  cancel (event) {
    event.preventDefault()
    this.close()
  }

  handleClose () {
    this.reset()
  }

  disableOnSubmit () {
    if (!this.hasSubmitTarget) return

    this.submitTarget.disabled = true
    this.submitTarget.classList.add('opacity-50', 'cursor-not-allowed')
  }

  handleSubmitEnd (event) {
    if (!this.hasSubmitTarget) return

    if (event.detail.success) {
      this.dialogTarget.close()
    } else {
      this.enableSubmitButton()
    }
  }

  reset () {
    if (this.hasInputTarget) {
      this.inputTarget.value = ''
    }

    if (this.hasSubmitTarget) {
      this.enableSubmitButton()
    }
  }

  focusInput () {
    if (!this.hasInputTarget) return

    window.requestAnimationFrame(() => {
      this.inputTarget.focus()
      this.inputTarget.select()
    })
  }

  enableSubmitButton () {
    this.submitTarget.disabled = false
    this.submitTarget.classList.remove('opacity-50', 'cursor-not-allowed')
  }
}
