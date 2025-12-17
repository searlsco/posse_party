import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['button', 'iconHide', 'iconShow', 'input']
  static values = { label: String }

  connect () {
    this.hide()
  }

  toggle () {
    this.inputTarget.type === 'password' ? this.show() : this.hide()
  }

  show () {
    this.inputTarget.type = 'text'
    this.iconShowTarget.classList.remove('hidden')
    this.iconHideTarget.classList.add('hidden')
    this.buttonTarget.setAttribute('aria-label', `Hide ${this.labelValue}`)
  }

  hide () {
    this.inputTarget.type = 'password'
    this.iconShowTarget.classList.add('hidden')
    this.iconHideTarget.classList.remove('hidden')
    this.buttonTarget.setAttribute('aria-label', `Show ${this.labelValue}`)
  }
}
