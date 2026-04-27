import { useState, useEffect } from 'react'

export type Theme = 'system' | 'light' | 'dark'

const STORAGE_KEY = 'kiss-theme'

function resolveEffective(theme: Theme): 'light' | 'dark' {
  if (theme !== 'system') return theme
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
}

export function useTheme() {
  const [theme, setThemeState] = useState<Theme>(
    () => (localStorage.getItem(STORAGE_KEY) as Theme | null) ?? '{theme}',
  )

  useEffect(() => {
    const effective = resolveEffective(theme)
    document.documentElement.classList.toggle('dark', effective === 'dark')
  }, [theme])

  // Track system preference changes when theme === 'system'
  useEffect(() => {
    if (theme !== 'system') return
    const mq = window.matchMedia('(prefers-color-scheme: dark)')
    const handler = () => {
      document.documentElement.classList.toggle('dark', mq.matches)
    }
    mq.addEventListener('change', handler)
    return () => mq.removeEventListener('change', handler)
  }, [theme])

  function setTheme(next: Theme) {
    localStorage.setItem(STORAGE_KEY, next)
    setThemeState(next)
  }

  return { theme, setTheme }
}
