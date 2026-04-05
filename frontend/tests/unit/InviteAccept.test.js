/* eslint-env jest */
import { mount, flushPromises } from '@vue/test-utils'
import { nextTick } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import InviteAccept from '../../src/views/InviteAccept.vue'
import { createTestRouter } from './setup'

jest.mock('../../src/services/api', () => ({
  post: jest.fn(),
  defaults: { headers: { common: {} } }
}))

const api = require('../../src/services/api')

const mountComponent = async ({ token = 'rawtoken123' } = {}) => {
  const pinia = createPinia()
  setActivePinia(pinia)
  const router = createTestRouter()
  await router.push(`/invite/accept?token=${token}`)
  await router.isReady()

  const showSnackbar = jest.fn()

  const wrapper = mount(InviteAccept, {
    global: {
      plugins: [pinia, router],
      provide: { showSnackbar }
    }
  })

  return { wrapper, showSnackbar, router }
}

beforeEach(() => {
  jest.clearAllMocks()
  localStorage.clear()
})

describe('InviteAccept.vue', () => {
  it('renders password and confirm password fields', async () => {
    const { wrapper } = await mountComponent()
    const inputs = wrapper.findAll('input[type="password"]')
    expect(inputs.length).toBe(2)
  })

  it('renders "Create Account" button', async () => {
    const { wrapper } = await mountComponent()
    expect(wrapper.text()).toContain('Create Account')
  })

  it('posts to /invitations/accept with token and passwords on submit', async () => {
    api.post.mockResolvedValue({
      data: { token: 'jwt', refresh_token: 'rtoken', user: { id: 1, email: 'a@example.com' } }
    })
    const { wrapper } = await mountComponent({ token: 'myrawtoken' })

    wrapper.vm.password = 'Password1!'
    wrapper.vm.passwordConfirmation = 'Password1!'
    await wrapper.vm.submit()

    expect(api.post).toHaveBeenCalledWith('/invitations/accept', {
      token: 'myrawtoken',
      password: 'Password1!',
      password_confirmation: 'Password1!'
    })
  })

  it('bootstraps user store and localStorage on success', async () => {
    const user = { id: 5, email: 'invited@example.com' }
    api.post.mockResolvedValue({ data: { token: 'jwt123', refresh_token: 'refresh456', user } })
    const { wrapper } = await mountComponent()

    wrapper.vm.password = 'Password1!'
    wrapper.vm.passwordConfirmation = 'Password1!'
    await wrapper.vm.submit()
    await nextTick()

    const { default: useUserStore } = await import('../../src/stores/UserStore.js')
    const store = useUserStore()
    expect(store.bearerToken).toBe('jwt123')
    expect(store.user).toEqual(user)
    expect(localStorage.getItem('bearerToken')).toBe('jwt123')
    expect(localStorage.getItem('refreshToken')).toBe('refresh456')
    expect(JSON.parse(localStorage.getItem('user'))).toEqual(user)
    expect(api.defaults.headers.common['Authorization']).toBe('Bearer jwt123')
  })

  it('redirects to Dashboard on success', async () => {
    api.post.mockResolvedValue({
      data: { token: 'jwt', refresh_token: 'rt', user: { id: 1 } }
    })
    const { wrapper, router } = await mountComponent()

    wrapper.vm.password = 'Password1!'
    wrapper.vm.passwordConfirmation = 'Password1!'
    await wrapper.vm.submit()
    await flushPromises()

    expect(router.currentRoute.value.name).toBe('Dashboard')
  })

  it('shows error snackbar when server returns errors', async () => {
    api.post.mockRejectedValue({ response: { data: { errors: ['Token is invalid or expired'] } } })
    const { wrapper, showSnackbar } = await mountComponent()

    wrapper.vm.password = 'Password1!'
    wrapper.vm.passwordConfirmation = 'Password1!'
    await wrapper.vm.submit()

    expect(showSnackbar).toHaveBeenCalledWith(['Token is invalid or expired'], 'error')
  })

  it('shows generic error snackbar when no error message in response', async () => {
    api.post.mockRejectedValue({})
    const { wrapper, showSnackbar } = await mountComponent()

    wrapper.vm.password = 'Password1!'
    wrapper.vm.passwordConfirmation = 'Password1!'
    await wrapper.vm.submit()

    expect(showSnackbar).toHaveBeenCalledWith(['An unknown error occurred'], 'error')
  })

  it('sets saving to false after successful submit', async () => {
    api.post.mockResolvedValue({
      data: { token: 'jwt', refresh_token: 'rt', user: { id: 1 } }
    })
    const { wrapper } = await mountComponent()

    wrapper.vm.password = 'Password1!'
    wrapper.vm.passwordConfirmation = 'Password1!'
    await wrapper.vm.submit()

    expect(wrapper.vm.saving).toBe(false)
  })

  it('sets saving to false after failed submit', async () => {
    api.post.mockRejectedValue({ response: { data: { errors: ['bad'] } } })
    const { wrapper } = await mountComponent()

    wrapper.vm.password = 'Password1!'
    wrapper.vm.passwordConfirmation = 'Password1!'
    await wrapper.vm.submit()

    expect(wrapper.vm.saving).toBe(false)
  })
})
