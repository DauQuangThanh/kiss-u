import { createI18n } from 'vue-i18n'

// Eagerly import all locale JSON files via Vite glob
const modules = import.meta.glob('../locales/*.json', {
  eager: true,
}) as Record<string, { default: Record<string, unknown> }>

const messages: Record<string, Record<string, unknown>> = {}
for (const path in modules) {
  const locale = path.replace('../locales/', '').replace('.json', '')
  messages[locale] = modules[path].default
}

const savedLocale = localStorage.getItem('kiss-locale')
const browserLocale = navigator.language.split('-')[0]
const availableLocales = Object.keys(messages)
const defaultLocale = availableLocales.includes(savedLocale ?? '')
  ? (savedLocale as string)
  : availableLocales.includes(browserLocale)
    ? browserLocale
    : 'en'

const i18n = createI18n({
  legacy: false,
  locale: defaultLocale,
  fallbackLocale: 'en',
  messages,
})

export default i18n
