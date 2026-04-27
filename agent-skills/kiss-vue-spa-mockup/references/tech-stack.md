# Vue 3 SPA Mockup — Tech Stack Reference

This file is loaded at runtime by the `kiss-vue-spa-mockup` skill
to give the AI grounding on the exact tech stack being scaffolded.

## Build tool — Vite ^6

- Zero-config dev server with HMR.
- Uses `@vitejs/plugin-vue` for Vue SFC support and Fast Refresh.
- Tailwind CSS integrated via `@tailwindcss/vite` — no PostCSS config
  needed; Tailwind v4 ships a Vite-native plugin.
- Path alias `@/` → `./src/` configured in `vite.config.ts` and mirrored
  in `tsconfig.app.json`.

## Language — TypeScript ~5.6

- Compiled via `vue-tsc` (Vue-aware TypeScript compiler).
- `tsconfig.app.json` extends `@vue/tsconfig/tsconfig.dom.json` which
  enables strict settings appropriate for browser + SFC environments.
- `tsconfig.node.json` covers `vite.config.ts` only.

## Styling — Tailwind CSS ^4 + CSS variables

- **Tailwind v4 import model**: `@import "tailwindcss"` in
  `src/assets/main.css` replaces the old `@tailwind` directives.
- **CSS variables** for design tokens (`--background`, `--primary`, etc.)
  defined in `@layer base`.
- **Dark mode** toggled by the `.dark` class on `<html>`.
  `useAppStore().toggleDark()` handles the toggle and persists state in
  the Pinia store.

## UI components — PrimeVue ^4 with Aura theme preset

- PrimeVue v4 uses a theme preset system (`@primeuix/themes`).
- The `Aura` preset is registered globally in `src/main.ts`:

  ```ts
  app.use(PrimeVue, { theme: { preset: Aura, options: { darkModeSelector: '.dark' } } })
  ```

- `darkModeSelector: '.dark'` keeps PrimeVue's dark tokens in sync with
  the Tailwind dark-mode class toggle.
- Icons: `primeicons` package — use `<i class="pi pi-<name>" />`.
- Add components from PrimeVue's component library as needed:
  `<Button>`, `<DataTable>`, `<Dialog>`, `<InputText>`, etc.
  All components are tree-shaken automatically.

## Routing — Vue Router ^4

- `createRouter` + `createWebHistory` (HTML5 history mode).
- Root routes are flat; nested layouts can be added by wrapping routes
  with a `component: RouterLayout` entry.
- `RouterLink` active styling uses `active-class` prop (no global
  `linkActiveClass` override needed for this mockup).

## State — Pinia ^3

- `useAppStore` (`src/stores/app.ts`) ships as the single starter store,
  holding `dark: boolean` and `toggleDark()`.
- Create additional stores under `src/stores/` following the same
  `defineStore('name', () => { … })` composition-API pattern.

## Key dependencies

| Package                  | Role                                          |
|--------------------------|-----------------------------------------------|
| `vue` ^3.5               | UI framework                                  |
| `vue-router` ^4.5        | Client-side routing                           |
| `pinia` ^3               | State management                              |
| `primevue` ^4.3          | Component library                             |
| `@primeuix/themes`       | PrimeVue theme preset system                  |
| `primeicons` ^7          | Icon font (tree-shakeable via CSS)            |
| `@tailwindcss/vite`      | Tailwind v4 Vite plugin (dev dep)             |
| `@vitejs/plugin-vue`     | Vue SFC + Fast Refresh (dev dep)              |
| `vue-tsc`                | Type-check & build compiler (dev dep)         |

## Extending the mockup

1. **Add a new view**: create `src/views/<Name>View.vue`, add an entry
   to `src/router/index.ts`, and add a `<RouterLink>` in `src/App.vue`.
2. **Add a PrimeVue component**: import directly from `primevue/<component>`:

   ```ts
   import Button from 'primevue/button'
   ```

3. **Add a store**: create `src/stores/<name>.ts` and export a
   `use<Name>Store` composable.
4. **Mock API data**: place JSON files in `public/` and fetch them with
   `useFetch` or `axios`; or use `msw` (Mock Service Worker) for a full
   mock API layer.
