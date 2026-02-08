/* eslint-env jest */
import { createRouter, createMemoryHistory } from 'vue-router'
import { setActivePinia, createPinia } from 'pinia'
import useUserStore from '../../src/stores/UserStore'

// Mock the API and tracking services
jest.mock('../../src/services/api', () => ({
  defaults: { headers: { common: {} } },
  post: jest.fn(),
  delete: jest.fn(),
  patch: jest.fn()
}))
jest.mock('../../src/services/ahoy.js', () => ({ trackEvent: jest.fn() }))

// Import components (these will be mocked)
jest.mock('../../src/views/Login.vue', () => ({ name: 'Login' }))
jest.mock('../../src/views/Signup.vue', () => ({ name: 'Signup' }))
jest.mock('../../src/views/Dashboard.vue', () => ({ name: 'Dashboard' }))
jest.mock('../../src/views/Confirmation.vue', () => ({ name: 'Confirmation' }))
jest.mock('../../src/views/PasswordEdit.vue', () => ({ name: 'PasswordEdit' }))
jest.mock('../../src/views/PasswordReset.vue', () => ({ name: 'PasswordReset' }))
jest.mock('../../src/views/Account.vue', () => ({ name: 'Account' }))
jest.mock('../../src/views/Roles.vue', () => ({ name: 'Roles' }))
jest.mock('../../src/views/Users.vue', () => ({ name: 'Users' }))

import router from '../../src/router/index.js'

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

describe('Router Configuration', () => {
  test('has all routes defined', () => {
    const routeNames = router.getRoutes().map(r => r.name)
    expect(routeNames).toContain('Login')
    expect(routeNames).toContain('Dashboard')
    expect(routeNames).toContain('Signup')
    expect(routeNames).toContain('Account')
    expect(routeNames).toContain('Roles')
    expect(routeNames).toContain('Users')
    expect(routeNames).toContain('PasswordReset')
    expect(routeNames).toContain('PasswordEdit')
    expect(routeNames).toContain('Confirmation')
  })

  test('login route exists with correct path', () => {
    const loginRoute = router.getRoutes().find(r => r.name === 'Login')
    expect(loginRoute).toBeDefined()
    expect(loginRoute.path).toBe('/login')
  })

  test('signup route exists with correct path', () => {
    const signupRoute = router.getRoutes().find(r => r.name === 'Signup')
    expect(signupRoute).toBeDefined()
    expect(signupRoute.path).toBe('/signup')
  })

  test('dashboard route exists with correct path', () => {
    const dashboardRoute = router.getRoutes().find(r => r.name === 'Dashboard')
    expect(dashboardRoute).toBeDefined()
    expect(dashboardRoute.path).toBe('/')
  })

  test('account route exists with correct path', () => {
    const accountRoute = router.getRoutes().find(r => r.name === 'Account')
    expect(accountRoute).toBeDefined()
    expect(accountRoute.path).toBe('/account')
  })

  test('roles route exists with correct path', () => {
    const rolesRoute = router.getRoutes().find(r => r.name === 'Roles')
    expect(rolesRoute).toBeDefined()
    expect(rolesRoute.path).toBe('/roles')
  })

  test('users route exists with correct path', () => {
    const usersRoute = router.getRoutes().find(r => r.name === 'Users')
    expect(usersRoute).toBeDefined()
    expect(usersRoute.path).toBe('/users')
  })
})

describe('Router Guards', () => {
  test('login guard redirects logged-in users to dashboard', (done) => {
    const store = useUserStore()
    store.bearerToken = 'token'
    store.user = { id: 1 }

    const mockNext = jest.fn()
    const loginRoute = router.getRoutes().find(r => r.name === 'Login')
    const beforeEnter = loginRoute.beforeEnter

    beforeEnter({}, {}, mockNext)

    expect(mockNext).toHaveBeenCalledWith({ name: 'Dashboard' })
    done()
  })

  test('login guard allows unauthenticated users', (done) => {
    const store = useUserStore()
    store.bearerToken = null
    store.user = null

    const mockNext = jest.fn()
    const loginRoute = router.getRoutes().find(r => r.name === 'Login')
    const beforeEnter = loginRoute.beforeEnter

    beforeEnter({}, {}, mockNext)

    expect(mockNext).toHaveBeenCalledWith()
    done()
  })

  test('signup guard redirects logged-in users to dashboard', (done) => {
    const store = useUserStore()
    store.bearerToken = 'token'
    store.user = { id: 1 }

    const mockNext = jest.fn()
    const signupRoute = router.getRoutes().find(r => r.name === 'Signup')
    const beforeEnter = signupRoute.beforeEnter

    beforeEnter({}, {}, mockNext)

    expect(mockNext).toHaveBeenCalledWith({ name: 'Dashboard' })
    done()
  })

  test('dashboard guard redirects unauthenticated users to login', (done) => {
    const store = useUserStore()
    store.bearerToken = null
    store.user = null

    const mockNext = jest.fn()
    const dashboardRoute = router.getRoutes().find(r => r.name === 'Dashboard')
    const beforeEnter = dashboardRoute.beforeEnter

    beforeEnter({}, {}, mockNext)

    expect(mockNext).toHaveBeenCalledWith({ name: 'Login' })
    done()
  })

  test('dashboard guard allows authenticated users', (done) => {
    const store = useUserStore()
    store.bearerToken = 'token'
    store.user = { id: 1 }

    const mockNext = jest.fn()
    const dashboardRoute = router.getRoutes().find(r => r.name === 'Dashboard')
    const beforeEnter = dashboardRoute.beforeEnter

    beforeEnter({}, {}, mockNext)

    expect(mockNext).toHaveBeenCalledWith()
    done()
  })

  test('account guard redirects unauthenticated users to dashboard', (done) => {
    const store = useUserStore()
    store.bearerToken = null
    store.user = null

    const mockNext = jest.fn()
    const accountRoute = router.getRoutes().find(r => r.name === 'Account')
    const beforeEnter = accountRoute.beforeEnter

    beforeEnter({}, {}, mockNext)

    expect(mockNext).toHaveBeenCalledWith({ name: 'Dashboard' })
    done()
  })

  test('account guard allows authenticated users', (done) => {
    const store = useUserStore()
    store.bearerToken = 'token'
    store.user = { id: 1 }

    const mockNext = jest.fn()
    const accountRoute = router.getRoutes().find(r => r.name === 'Account')
    const beforeEnter = accountRoute.beforeEnter

    beforeEnter({}, {}, mockNext)

    expect(mockNext).toHaveBeenCalledWith()
    done()
  })

  test('roles guard redirects non-admin users to dashboard', (done) => {
    const store = useUserStore()
    store.bearerToken = 'token'
    store.user = { id: 1, roles: [{ name: 'user' }] }

    const mockNext = jest.fn()
    const rolesRoute = router.getRoutes().find(r => r.name === 'Roles')
    const beforeEnter = rolesRoute.beforeEnter

    beforeEnter({}, {}, mockNext)

    expect(mockNext).toHaveBeenCalledWith({ name: 'Dashboard' })
    done()
  })

  test('roles guard allows admin users', (done) => {
    const store = useUserStore()
    store.bearerToken = 'token'
    store.user = { id: 1, roles: [{ name: 'admin' }] }

    const mockNext = jest.fn()
    const rolesRoute = router.getRoutes().find(r => r.name === 'Roles')
    const beforeEnter = rolesRoute.beforeEnter

    beforeEnter({}, {}, mockNext)

    expect(mockNext).toHaveBeenCalledWith()
    done()
  })

  test('roles guard redirects unauthenticated users to dashboard', (done) => {
    const store = useUserStore()
    store.bearerToken = null
    store.user = null

    const mockNext = jest.fn()
    const rolesRoute = router.getRoutes().find(r => r.name === 'Roles')
    const beforeEnter = rolesRoute.beforeEnter

    beforeEnter({}, {}, mockNext)

    expect(mockNext).toHaveBeenCalledWith({ name: 'Dashboard' })
    done()
  })

  test('users guard redirects non-admin users to dashboard', (done) => {
    const store = useUserStore()
    store.bearerToken = 'token'
    store.user = { id: 1, roles: [{ name: 'user' }] }

    const mockNext = jest.fn()
    const usersRoute = router.getRoutes().find(r => r.name === 'Users')
    const beforeEnter = usersRoute.beforeEnter

    beforeEnter({}, {}, mockNext)

    expect(mockNext).toHaveBeenCalledWith({ name: 'Dashboard' })
    done()
  })

  test('users guard allows admin users', (done) => {
    const store = useUserStore()
    store.bearerToken = 'token'
    store.user = { id: 1, roles: [{ name: 'admin' }] }

    const mockNext = jest.fn()
    const usersRoute = router.getRoutes().find(r => r.name === 'Users')
    const beforeEnter = usersRoute.beforeEnter

    beforeEnter({}, {}, mockNext)

    expect(mockNext).toHaveBeenCalledWith()
    done()
  })

  test('users guard redirects unauthenticated users to dashboard', (done) => {
    const store = useUserStore()
    store.bearerToken = null
    store.user = null

    const mockNext = jest.fn()
    const usersRoute = router.getRoutes().find(r => r.name === 'Users')
    const beforeEnter = usersRoute.beforeEnter

    beforeEnter({}, {}, mockNext)

    expect(mockNext).toHaveBeenCalledWith({ name: 'Dashboard' })
    done()
  })
})

describe('Public Routes', () => {
  test('confirmation route has no guards', () => {
    const confirmationRoute = router.getRoutes().find(r => r.name === 'Confirmation')
    expect(confirmationRoute.beforeEnter).toBeUndefined()
  })

  test('password reset route has no guards', () => {
    const resetRoute = router.getRoutes().find(r => r.name === 'PasswordReset')
    expect(resetRoute.beforeEnter).toBeUndefined()
  })

  test('password edit route has no guards', () => {
    const editRoute = router.getRoutes().find(r => r.name === 'PasswordEdit')
    expect(editRoute.beforeEnter).toBeUndefined()
  })
})
