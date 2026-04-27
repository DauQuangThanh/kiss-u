import { createRouter, createWebHistory } from 'vue-router'
{router_imports}
const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
{router_routes}
  ],
})

export default router
