import { NavLink, Outlet } from 'react-router-dom'
import { Moon, Sun, Monitor, Languages } from 'lucide-react'
import { useTheme } from '@/hooks/useTheme'
import { useTranslation } from 'react-i18next'

export default function App() {
  const { theme, setTheme } = useTheme()
  const { i18n } = useTranslation()

  const themeIcons: Record<string, React.ReactNode> = {
    light:  <Sun size={16} />,
    dark:   <Moon size={16} />,
    system: <Monitor size={16} />,
  }
  const nextTheme: Record<string, 'light' | 'dark' | 'system'> = {
    system: 'light',
    light:  'dark',
    dark:   'system',
  }

  const locales = Object.keys(i18n.services.resourceStore?.data ?? {})

  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="border-b">
        <div className="container mx-auto flex items-center justify-between px-4 py-3">
          <span className="font-bold tracking-tight">{app_name}</span>
          <nav className="flex items-center gap-6 text-sm">
{nav_links}
          </nav>
          <div className="flex items-center gap-2">
            {locales.length > 1 && (
              <div className="flex items-center gap-1">
                <Languages size={14} className="text-muted-foreground" />
                {locales.map((lng) => (
                  <button
                    key={lng}
                    onClick={() => i18n.changeLanguage(lng)}
                    className={`rounded px-1.5 py-0.5 text-xs font-mono uppercase transition-colors ${
                      i18n.language === lng
                        ? 'bg-primary text-primary-foreground'
                        : 'text-muted-foreground hover:text-foreground hover:bg-accent'
                    }`}
                  >
                    {lng}
                  </button>
                ))}
              </div>
            )}
            <button
              aria-label={`Switch theme (current: ${theme})`}
              onClick={() => setTheme(nextTheme[theme])}
              className="rounded-md p-2 hover:bg-accent transition-colors"
              title={`Theme: ${theme}`}
            >
              {themeIcons[theme]}
            </button>
          </div>
        </div>
      </header>
      <main className="container mx-auto px-4 py-8">
        <Outlet />
      </main>
    </div>
  )
}
