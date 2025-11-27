function colorify (name) {
  return `var(--${name})`
}

const customColors = {
  colors: Object.assign({}, {
    'border-primary': colorify('border-primary'),
    'border-secondary': colorify('border-secondary'),
    'text-primary': colorify('text-primary'),
    'text-secondary': colorify('text-secondary')
  }),
  backgroundColor: Object.assign({}, {
    DEFAULT: colorify('bg-primary'),
    primary: colorify('bg-primary'),
    secondary: colorify('bg-secondary'),
    tertiary: colorify('bg-tertiary'),
    inverted: colorify('bg-inverted'),
    accent: colorify('accent-bg'),
    'accent-solid': colorify('accent-bg-solid'),
    info: colorify('info-bg'),
    'info-solid': colorify('info-bg-solid'),
    warn: colorify('warn-bg'),
    'warn-solid': colorify('warn-bg-solid'),
    danger: colorify('danger-bg'),
    'danger-solid': colorify('danger-bg-solid'),
    success: colorify('success-bg'),
    'success-solid': colorify('success-bg-solid'),
    neutral: colorify('neutral-bg'),
    'neutral-solid': colorify('neutral-bg-solid')
  }),
  borderColor: Object.assign({}, {
    DEFAULT: colorify('border-primary'),
    primary: colorify('border-primary'),
    secondary: colorify('border-secondary'),
    tertiary: colorify('border-tertiary'),
    inverted: colorify('border-inverted'),
    bgInverted: colorify('bg-inverted'),
    accent: colorify('accent-border'),
    'accent-solid': colorify('accent-border'), // Use regular border color for -solid variants
    info: colorify('info-border'),
    'info-solid': colorify('info-border'),
    warn: colorify('warn-border'),
    'warn-solid': colorify('warn-border'),
    danger: colorify('danger-border'),
    'danger-solid': colorify('danger-border'),
    success: colorify('success-border'),
    'success-solid': colorify('success-border'),
    neutral: colorify('neutral-border'),
    'neutral-solid': colorify('neutral-border')
  }),
  fill: Object.assign({}, {
    primary: colorify('text-primary'),
    secondary: colorify('text-secondary'),
    inverted: colorify('text-inverted')
  }),
  textColor: Object.assign({}, {
    DEFAULT: colorify('text-primary'),
    primary: colorify('text-primary'),
    secondary: colorify('text-secondary'),
    tertiary: colorify('text-tertiary'),
    inverted: colorify('text-inverted'),
    accent: colorify('accent'),
    info: colorify('info'),
    warn: colorify('warn'),
    danger: colorify('danger'),
    success: colorify('success'),
    neutral: colorify('neutral'),
    solid: colorify('text-solid') // Single solid text color for high contrast on solid backgrounds
  })
}

module.exports = {
  content: [
    './public/**/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/lib/**/*.rb',
    './app/assets/stylesheets/**/*.css'
  ],
  theme: {
    extend: Object.assign({}, customColors, {
    })
  }
}
