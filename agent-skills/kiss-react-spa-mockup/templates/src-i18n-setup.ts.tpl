import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'
import LanguageDetector from 'i18next-browser-languagedetector'

// Eagerly import all locale JSON files via Vite glob
const modules = import.meta.glob('../locales/*.json', {
  eager: true,
}) as Record<string, { default: Record<string, unknown> }>

const resources: Record<string, { translation: Record<string, unknown> }> = {}
for (const path in modules) {
  const locale = path.replace('../locales/', '').replace('.json', '')
  resources[locale] = { translation: modules[path].default }
}

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources,
    fallbackLng: 'en',
    detection: {
      order: ['localStorage', 'navigator'],
      caches: ['localStorage'],
      lookupLocalStorage: 'kiss-locale',
    },
    interpolation: {
      escapeValue: false,
    },
  })

export default i18n
