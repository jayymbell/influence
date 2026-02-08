/* eslint-env jest */
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import Account from '../../src/views/Account.vue'
import useUserStore from '../../src/stores/UserStore'

// Mock API service to avoid import.meta issues
jest.mock('../../src/services/api', () => ({
  defaults: { headers: { common: {} } },
  get: jest.fn(),
  post: jest.fn(),
  put: jest.fn(),
  delete: jest.fn(),
  patch: jest.fn()
}))

// Mock router
const mockRouter = {
  push: jest.fn()
}

// Mock vue-router composables
jest.mock('vue-router', () => ({
  useRouter: () => mockRouter
}))

const mockShowSnackbar = jest.fn()

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

describe('Account.vue', () => {
  const createComponent = () => {
    const userStore = useUserStore()
    userStore.user = {
      id: 1,
      email: 'user@example.com',
      created_at: '2023-01-01T00:00:00Z',
      roles: [{ id: 1, name: 'admin' }]
    }
    
    return mount(Account, {
      global: {
        mocks: {
          $router: mockRouter
        },
        provide: {
          showSnackbar: mockShowSnackbar,
          'Symbol(router)': mockRouter
        },
        stubs: {
          VContainer: true,
          VCard: true,
          UpdateAccount: true
        }
      }
    })
  }

  test('component mounts successfully', () => {
    const wrapper = createComponent()
    expect(wrapper.exists()).toBe(true)
  })

  test('displays account title', () => {
    const wrapper = createComponent()
    expect(wrapper.text()).toContain('Account')
  })

  test('shows user information in view mode', async () => {
    const wrapper = createComponent()
    await wrapper.vm.$nextTick()
    
    expect(wrapper.text()).toContain('User')
    expect(wrapper.text()).toContain('user@example.com')
    expect(wrapper.text()).toContain('member since 2023')
  })

  test('displays user roles', async () => {
    const wrapper = createComponent()
    await wrapper.vm.$nextTick()
    
    expect(wrapper.vm.roles).toBe('admin')
  })

  test('switches to change email mode', async () => {
    const wrapper = createComponent()
    
    wrapper.vm.mode = 'change_email'
    await wrapper.vm.$nextTick()
    
    expect(wrapper.vm.mode).toBe('change_email')
    expect(wrapper.vm.form_title).toBe('Change Email')
  })

  test('switches to change password mode', async () => {
    const wrapper = createComponent()
    
    wrapper.vm.mode = 'change_password'
    await wrapper.vm.$nextTick()
    
    expect(wrapper.vm.mode).toBe('change_password')
    expect(wrapper.vm.form_title).toBe('Change Password')
  })

  test('returns to view mode when closed', async () => {
    const wrapper = createComponent()
    
    wrapper.vm.mode = 'change_email'
    await wrapper.vm.$nextTick()
    
    wrapper.vm.mode = 'view'
    await wrapper.vm.$nextTick()
    
    expect(wrapper.vm.mode).toBe('view')
  })

  test('computed est returns correct year', () => {
    const wrapper = createComponent()
    expect(wrapper.vm.est).toBe(2023)
  })

  test('computed roles joins role names', () => {
    const wrapper = createComponent()
    expect(wrapper.vm.roles).toBe('admin')
  })
})