<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useI18n } from 'vue-i18n'

const app = useAppStore()
const { locale, availableLocales } = useI18n()

const nextTheme: Record<string, 'system' | 'light' | 'dark'> = {
  system: 'light',
  light: 'dark',
  dark: 'system',
}

const themeIcon: Record<string, string> = {
  light: 'pi pi-sun',
  dark: 'pi pi-moon',
  system: 'pi pi-desktop',
}
</script>

<template>
  <div class="min-h-screen bg-background text-foreground">
    <header class="border-b border-border">
      <div class="container mx-auto flex items-center justify-between px-4 py-3">
        <span class="font-bold tracking-tight">{app_name}</span>
        <nav class="flex items-center gap-6 text-sm">
{nav_links}
        </nav>
        <div class="flex items-center gap-2">
          <div v-if="availableLocales.length > 1" class="flex items-center gap-1">
            <i class="pi pi-language text-muted-foreground text-xs" />
            <button
              v-for="lng in availableLocales"
              :key="lng"
              class="rounded px-1.5 py-0.5 text-xs font-mono uppercase transition-colors"
              :class="locale === lng
                ? 'bg-primary text-primary-foreground'
                : 'text-muted-foreground hover:text-foreground hover:bg-accent'"
              @click="locale = lng"
            >
              {{ lng }}
            </button>
          </div>
          <button
            :aria-label="`Switch theme (current: ${app.theme})`"
            class="rounded-md p-2 hover:bg-accent transition-colors"
            :title="`Theme: ${app.theme}`"
            @click="app.setTheme(nextTheme[app.theme])"
          >
            <i :class="themeIcon[app.theme]" />
          </button>
        </div>
      </div>
    </header>
    <main class="container mx-auto px-4 py-8">
      <RouterView />
    </main>
  </div>
</template>
