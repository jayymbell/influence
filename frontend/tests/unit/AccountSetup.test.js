/* eslint-env jest */
import { mount, flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { createTestRouter } from './setup.js'

jest.mock('../../src/services/api', () => ({
  defaults: { headers: { common: {} } },
  get: jest.fn(),
  post: jest.fn(),
  patch: jest.fn(),
  delete: jest.fn()
}))
jest.mock('../../src/services/ahoy.js', () => ({ trackEvent: jest.fn() }))
jest.mock('../../src/components/PersonForm.vue', () => ({
  name: 'PersonForm',
  template: '<div class="person-form" />'
}))

const api = require('../../src/services/api')
const { trackEvent } = require('../../src/services/ahoy.js')

import AccountSetup from '../../src/views/AccountSetup.vue'
import useUserStore from '../../src/stores/UserStore.js'

const showSnackbar = jest.fn()

const mountComponent = (router) => mount(AccountSetup, {
  global: {
    plugins: [createPinia(), router],
    provide: { showSnackbar },
    stubs: {
      'v-container': { template: '<div><slot /></div>' },
      'v-row': { template: '<div><slot /></div>' },
      'v-col': { template: '<div><slot /></div>' },
      'v-card': { template: '<div><slot /></div>' },
      'v-btn': { template: '<button @click="$attrs.onClick?.()"><slot /></button>', inheritAttrs: false }
    }
  }
})

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

describe('AccountSetup.vue', () => {
  describe('rendering', () => {
    it('renders the welcome heading', async () => {
      const router = createTestRouter()
      const wrapper = mountComponent(router)
      expect(wrapper.text()).toContain('Welcome!')
    })

    it('renders the Save and Continue button', async () => {
      const router = createTestRouter()
      const wrapper = mountComponent(router)
      expect(wrapper.text()).toContain('Save and Continue')
    })

    it('includes the PersonForm component', async () => {
      const router = createTestRouter()
      const wrapper = mountComponent(router)
      expect(wrapper.findComponent({ name: 'PersonForm' }).exists()).toBe(true)
    })
  })

  describe('submit', () => {
    it('POSTs to /people with form data and redirects to Dashboard on success', async () => {
      const router = createTestRouter()
      await router.push('/account-setup')
      api.post.mockResolvedValue({ data: { person: { id: 5 } } })

      const wrapper = mountComponent(router)
      const store = useUserStore()
      store.user = { id: 1, roles: [] }

      await wrapper.find('button').trigger('click')
      await flushPromises()

      expect(api.post).toHaveBeenCalledWith('/people', { person: expect.objectContaining({ first_name: '' }) })
      expect(store.user.person_id).toBe(5)
      expect(router.currentRoute.value.name).toBe('Dashboard')
    })

    it('tracks the profile setup event on success', async () => {
      const router = createTestRouter()
      api.post.mockResolvedValue({ data: { person: { id: 7 } } })

      const wrapper = mountComponent(router)
      const store = useUserStore()
      store.user = { id: 1, roles: [] }

      await wrapper.find('button').trigger('click')
      await flushPromises()

      expect(trackEvent).toHaveBeenCalledWith('completed profile setup', { person_id: 7 })
    })

    it('shows snackbar errors when POST fails', async () => {
      const router = createTestRouter()
      api.post.mockRejectedValue({ response: { data: { errors: ['First name is required'] } } })

      const wrapper = mountComponent(router)

      await wrapper.find('button').trigger('click')
      await flushPromises()

      expect(showSnackbar).toHaveBeenCalledWith(['First name is required'], 'error')
    })

    it('shows fallback error message when no errors in response', async () => {
      const router = createTestRouter()
      api.post.mockRejectedValue({})

      const wrapper = mountComponent(router)

      await wrapper.find('button').trigger('click')
      await flushPromises()

      expect(showSnackbar).toHaveBeenCalledWith(['An unknown error occurred'], 'error')
    })
  })
})
