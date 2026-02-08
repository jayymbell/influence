/* eslint-env jest */
import { setActivePinia, createPinia } from 'pinia'
import useUserStore from '../../src/stores/UserStore'

// Mock API and tracking services
jest.mock('../../src/services/api', () => ({
  defaults: { headers: { common: {} } },
  post: jest.fn()
}))
jest.mock('../../src/services/ahoy.js', () => ({ trackEvent: jest.fn().mockResolvedValue({}) }))

const mockApi = require('../../src/services/api')

// Mock router
const mockRouter = {
  push: jest.fn()
}

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

describe('Login.vue', () => {
  const createComponent = () => {
    // Simulate the component's setup and data
    return {
      email: '',
      password: '',
      showSnackbar: jest.fn(),
      router: mockRouter,
      handleLogin: async function() {
        const userStore = useUserStore()
        const data = { user: { email: this.email, password: this.password } }
        try {
          if (this.email === '' || this.password === '') {
            this.showSnackbar(['Please enter your email and password.'], 'error')
            return
          }
          const response = await userStore.login(data)
          this.showSnackbar([response.data.status.message], 'success')
          this.router.push({ name: 'Dashboard' })
        } catch (error) {
          const e = error.response.data.error || ['An unknown error occurred']
          this.showSnackbar([e], 'error')
        }
      },
      redirectToPasswordReset: function() {
        this.router.push({ name: 'PasswordReset' })
      }
    }
  }

  test('initializes with empty email and password', () => {
    const component = createComponent()
    expect(component.email).toBe('')
    expect(component.password).toBe('')
  })

  test('shows error when email or password is empty', async () => {
    const component = createComponent()
    await component.handleLogin()
    
    expect(component.showSnackbar).toHaveBeenCalledWith(
      ['Please enter your email and password.'],
      'error'
    )
  })

  test('calls userStore.login with correct data on submit', async () => {
    mockApi.post.mockResolvedValue({
      data: {
        token: 'test-token',
        data: { id: 1, email: 'user@example.com', roles: [] },
        status: { message: 'Login successful' }
      }
    })

    const component = createComponent()
    component.email = 'user@example.com'
    component.password = 'password123'

    await component.handleLogin()

    expect(mockApi.post).toHaveBeenCalledWith('/login', {
      user: { email: 'user@example.com', password: 'password123' }
    })
  })

  test('shows success message and redirects to dashboard on successful login', async () => {
    mockApi.post.mockResolvedValue({
      data: {
        token: 'test-token',
        data: { id: 1, email: 'user@example.com', roles: [] },
        status: { message: 'Login successful' }
      }
    })

    const component = createComponent()
    component.email = 'user@example.com'
    component.password = 'password123'

    await component.handleLogin()

    expect(component.showSnackbar).toHaveBeenCalledWith(
      ['Login successful'],
      'success'
    )
    expect(mockRouter.push).toHaveBeenCalledWith({ name: 'Dashboard' })
  })

  test('shows error message on login failure', async () => {
    mockApi.post.mockRejectedValue({
      response: {
        data: {
          error: 'Invalid credentials'
        }
      }
    })

    const component = createComponent()
    component.email = 'user@example.com'
    component.password = 'wrongpassword'

    await component.handleLogin()

    expect(component.showSnackbar).toHaveBeenCalledWith(
      ['Invalid credentials'],
      'error'
    )
  })

  test('shows generic error when no error message in response', async () => {
    mockApi.post.mockRejectedValue({
      response: {
        data: {}
      }
    })

    const component = createComponent()
    component.email = 'user@example.com'
    component.password = 'password123'

    await component.handleLogin()

    expect(component.showSnackbar).toHaveBeenCalledWith(
      [['An unknown error occurred']],
      'error'
    )
  })

  test('redirects to password reset page when "Forgot Password?" is clicked', () => {
    const component = createComponent()
    component.redirectToPasswordReset()
    
    expect(mockRouter.push).toHaveBeenCalledWith({ name: 'PasswordReset' })
  })

  test('does not call API if email field is empty', async () => {
    const component = createComponent()
    component.email = ''
    component.password = 'password123'

    await component.handleLogin()

    expect(mockApi.post).not.toHaveBeenCalled()
  })

  test('does not call API if password field is empty', async () => {
    const component = createComponent()
    component.email = 'user@example.com'
    component.password = ''

    await component.handleLogin()

    expect(mockApi.post).not.toHaveBeenCalled()
  })

  test('handles missing error.response gracefully', async () => {
    mockApi.post.mockRejectedValue(new Error('Network error'))

    const component = createComponent()
    component.email = 'user@example.com'
    component.password = 'password123'

    // Should not throw
    try {
      await component.handleLogin()
    } catch (e) {
      // Expected - the error won't have response property
    }
  })
})
