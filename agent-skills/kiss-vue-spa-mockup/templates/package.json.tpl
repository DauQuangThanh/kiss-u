{
  "name": "{app_name}",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc -b && vite build",
    "preview": "vite preview",
    "type-check": "vue-tsc --build --force"
  },
  "dependencies": {
    "@primeuix/themes": "^1.0.0",
    "pinia": "^3.0.0",
    "primevue": "^4.3.0",
    "primeicons": "^7.0.0",
    "vue": "^3.5.0",
    "vue-i18n": "^9.14.0",
    "vue-router": "^4.5.0"
  },
  "devDependencies": {
    "@tailwindcss/vite": "^4.0.7",
    "@vitejs/plugin-vue": "^5.2.0",
    "tailwindcss": "^4.0.7",
    "typescript": "~5.6.2",
    "vite": "^6.0.5",
    "vue-tsc": "^2.2.0"
  }
}
