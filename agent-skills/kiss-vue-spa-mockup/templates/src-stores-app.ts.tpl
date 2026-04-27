import { defineStore } from 'pinia'
import { ref, watch } from 'vue'

export type Theme = 'system' | 'light' | 'dark'

const STORAGE_KEY = 'kiss-theme'

function resolveEffective(theme: Theme): 'light' | 'dark' {
  if (theme !== 'system') return theme
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
}

export const useAppStore = defineStore('app', () => {
  const theme = ref<Theme>(
    (localStorage.getItem(STORAGE_KEY) as Theme | null) ?? '{theme}',
  )

  watch(
    theme,
    (val) => {
      document.documentElement.classList.toggle('dark', resolveEffective(val) === 'dark')
    },
    { immediate: true },
  )

  // Keep .dark in sync when OS preference changes while theme === 'system'
  const mq = window.matchMedia('(prefers-color-scheme: dark)')
  mq.addEventListener('change', () => {
    if (theme.value === 'system') {
      document.documentElement.classList.toggle('dark', mq.matches)
    }
  })

  function setTheme(next: Theme) {
    localStorage.setItem(STORAGE_KEY, next)
    theme.value = next
  }

  return { theme, setTheme }
})
