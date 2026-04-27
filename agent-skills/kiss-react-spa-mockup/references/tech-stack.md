# React SPA Mockup — Tech Stack Reference

This file is loaded at runtime by the `kiss-react-spa-mockup` skill
to give the AI grounding on the exact tech stack being scaffolded.

## Build tool — Vite ^6

- Zero-config dev server with HMR.
- Uses `@vitejs/plugin-react` (Babel-based Fast Refresh).
- Tailwind CSS integrated via `@tailwindcss/vite` — no PostCSS config
  needed; Tailwind v4 ships a Vite-native plugin.
- Path alias `@/` → `./src/` configured in `vite.config.ts` and mirrored
  in `tsconfig.app.json`.

## Language — TypeScript ~5.6

- `strict: true` enabled.
- `moduleResolution: "bundler"` (Vite-idiomatic).
- `allowImportingTsExtensions: true` (no emit; Vite handles transpile).
- `noUncheckedSideEffectImports: true` guards against accidental global
  side-effect imports.

## Styling — Tailwind CSS ^4 + shadcn/ui

- **Tailwind v4 import model**: `@import "tailwindcss"` in `src/index.css`
  replaces the old `@tailwind base/components/utilities` directives.
- **CSS variables** for design tokens (`--background`, `--primary`, etc.)
  defined in `@layer base` in `src/index.css`.
- **Dark mode** toggled by the `.dark` class on `<html>` (Tailwind v4
  `darkMode: 'class'` is the default behaviour).
- **shadcn/ui**: copy-paste component primitives built on Radix UI.
  Run `npx shadcn@latest add <component>` after `npm install` to add
  individual components (Button, Card, Dialog, etc.).
- **`cn()` helper** (`src/lib/utils.ts`): `clsx` + `tailwind-merge`
  for conditional class composition.

## Routing — React Router ^7 (react-router-dom)

- `createBrowserRouter` + `RouterProvider` (data router, Remix-style).
- Root route renders `<App />` as the layout shell (header + `<Outlet />`).
- Each page is a child route rendered inside the `<Outlet />`.
- No server-side rendering; `index.html` catch-all configured automatically
  by Vite's dev server.

## Key dependencies

| Package                  | Role                                      |
|--------------------------|-------------------------------------------|
| `react` ^19              | UI library                                |
| `react-dom` ^19          | DOM renderer                              |
| `react-router-dom` ^7    | Client-side routing                       |
| `@radix-ui/react-slot`   | shadcn/ui slot primitive                  |
| `class-variance-authority` | shadcn/ui variant helper               |
| `clsx`                   | Conditional class list builder            |
| `tailwind-merge`         | Merge conflicting Tailwind classes        |
| `lucide-react`           | Icon set (tree-shakeable)                 |
| `@tailwindcss/vite`      | Tailwind v4 Vite plugin (dev dep)         |
| `@vitejs/plugin-react`   | React Fast Refresh (dev dep)              |

## Adding shadcn/ui components

After `npm install`, add components with:

```bash
npx shadcn@latest add button
npx shadcn@latest add card
npx shadcn@latest add input
# … etc.
```

Components are written to `src/components/ui/`.

## Extending the mockup

1. Add a new page: create `src/pages/<PageName>.tsx`, add an entry to
   `src/router.tsx`, and add a `<NavLink>` in `src/App.tsx`.
2. Add shared state: create a React context or a lightweight store
   (e.g. Zustand) under `src/store/`.
3. Fetch mock data: use `fetch` with a local JSON file in `public/` or
   a mock API like `msw` (Mock Service Worker).
