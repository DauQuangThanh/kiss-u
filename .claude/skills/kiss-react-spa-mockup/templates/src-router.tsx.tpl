import { createBrowserRouter } from 'react-router-dom'
import App from './App'
{router_imports}
const router = createBrowserRouter([
  {
    path: '/',
    element: <App />,
    children: [
{router_routes}
    ],
  },
])

export default router
