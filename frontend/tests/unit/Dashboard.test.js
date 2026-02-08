/* eslint-env jest */
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import Dashboard from '../../src/views/Dashboard.vue'
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

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

describe('Dashboard.vue', () => {
  const createComponent = () => {
    return mount(Dashboard, {
      global: {
        stubs: {
          VContainer: true
        }
      }
    })
  }

  test('component mounts successfully', () => {
    const wrapper = createComponent()
    expect(wrapper.exists()).toBe(true)
  })

  test('displays dashboard title', () => {
    const wrapper = createComponent()
    expect(wrapper.text()).toContain('Dashboard')
  })

  test('initializes userStore correctly', () => {
    const wrapper = createComponent()
    expect(wrapper.vm.userStore).toBeDefined()
    // Router is accessed via composition API, not available as vm property
  })

  test('userStore is accessible from component', () => {
    const wrapper = createComponent()
    const userStore = wrapper.vm.userStore
    expect(typeof userStore.login).toBe('function')
    expect(typeof userStore.logout).toBe('function')
  })
})