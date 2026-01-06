;(() => {
  const attachTimeWidget = () => {
    const widget = document.querySelector('[data-time-widget]')
    if (!widget) return

    const options = Array.from(widget.querySelectorAll('.time-widget-option'))
    const optionsContainer = widget.querySelector('.time-widget-options')
    const track = widget.querySelector('[data-time-track]')
    const screenshot = widget.querySelector('[data-time-screenshot]')
    const video = widget.querySelector('[data-time-video]')
    const placeholderYoutubeEmbed = widget.dataset.placeholderYoutubeEmbed

    const clampStep = (step) => Math.min(options.length - 1, Math.max(0, step))

    const setStep = (nextStep, { focus = false } = {}) => {
      widget.dataset.step = String(nextStep)

      options.forEach((option, index) => {
        const selected = index === nextStep
        option.setAttribute('aria-checked', selected ? 'true' : 'false')
        option.tabIndex = selected ? 0 : -1
      })

      const selectedOption = options[nextStep]
      const showVideo = nextStep !== 0

      screenshot.hidden = showVideo
      video.hidden = !showVideo

      if (showVideo) {
        const embed = selectedOption.dataset.youtubeEmbed || placeholderYoutubeEmbed
        if (video.getAttribute('src') !== embed) video.src = embed
        video.title = `POSSE Party demo video (${selectedOption.dataset.timeValue})`
      } else {
        video.removeAttribute('src')
      }

      if (focus) selectedOption.focus()
    }

    const stepFromClientX = (clientX, { left, width }) =>
      clampStep(Math.round(((clientX - left) / width) * (options.length - 1)))

    setStep(clampStep(Number(widget.dataset.step || 0)))

    options.forEach((option, index) => {
      option.addEventListener('click', () => setStep(index, { focus: true }))

      option.addEventListener('keydown', (event) => {
        if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return
        event.preventDefault()

        const currentStep = clampStep(Number(widget.dataset.step || 0))

        setStep(
          clampStep({
            ArrowLeft: currentStep - 1,
            ArrowRight: currentStep + 1,
            Home: 0,
            End: options.length - 1
          }[event.key]),
          { focus: true }
        )
      })
    })

    let dragBounds

    track.addEventListener('pointerdown', (event) => {
      dragBounds = optionsContainer.getBoundingClientRect()
      track.setPointerCapture(event.pointerId)
      widget.classList.add('is-dragging')
      setStep(stepFromClientX(event.clientX, dragBounds))
      event.preventDefault()
    })

    track.addEventListener('pointermove', (event) => {
      if (!dragBounds) return
      setStep(stepFromClientX(event.clientX, dragBounds))
      event.preventDefault()
    })

    const endDrag = () => {
      dragBounds = undefined
      widget.classList.remove('is-dragging')
    }

    track.addEventListener('pointerup', endDrag)
    track.addEventListener('pointercancel', endDrag)
  }

  const attachTerminalCopy = () => {
    const terminals = Array.from(document.querySelectorAll('[data-terminal]'))
    if (terminals.length === 0) return

    terminals.forEach((terminal) => {
      const button = terminal.querySelector('[data-terminal-copy]')
      const text = terminal.querySelector('[data-terminal-text]')

      if (!button || !text) return

      button.addEventListener('click', async () => {
        const content = text.textContent.trim()
        if (!content) return

        button.dataset.copied = 'true'
        clearTimeout(button._copyResetTimeoutId)
        button._copyResetTimeoutId = setTimeout(() => {
          delete button.dataset.copied
        }, 2000)

        try {
          await navigator.clipboard.writeText(content)
        } catch {
          const selection = window.getSelection()
          const range = document.createRange()
          range.selectNodeContents(text)
          selection.removeAllRanges()
          selection.addRange(range)
          document.execCommand('copy')
          selection.removeAllRanges()
        }
      })
    })
  }

  attachTimeWidget()
  attachTerminalCopy()
})()
