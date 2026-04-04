/* eslint-env jest */
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import People from '../../src/views/People.vue'
import { createTestRouter } from './setup'

jest.mock('../../src/services/api', () => ({
  get: jest.fn(),
  post: jest.fn(),
  patch: jest.fn(),
  delete: jest.fn(),
  defaults: { headers: { common: {} } }
}))

jest.mock('../../src/services/ahoy.js', () => ({ trackEvent: jest.fn() }))

jest.mock('lodash', () => ({
  ...jest.requireActual('lodash'),
  debounce: (fn) => fn
}))

const api = require('../../src/services/api')
const { trackEvent } = require('../../src/services/ahoy.js')

const mockPeople = [
  { id: 1, display_name: 'Alice Smith', first_name: 'Alice', last_name: 'Smith', email: 'alice@example.com', title: 'Director', organization_name: 'Acme', phone: '', notes: '', discarded_at: null, user: null, created_by: null, updated_by: null },
  { id: 2, display_name: 'Bob Jones', first_name: 'Bob', last_name: 'Jones', email: '', title: '', organization_name: '', phone: '', notes: '', discarded_at: null, user: null, created_by: null, updated_by: null }
]

const mountComponent = async () => {
  const pinia = createPinia()
  setActivePinia(pinia)
  const router = createTestRouter()
  await router.push('/people')
  await router.isReady()

  const showSnackbar = jest.fn()

  const wrapper = mount(People, {
    global: {
      plugins: [pinia, router],
      provide: { showSnackbar },
      stubs: {
        'PersonForm': { template: '<div class="person-form" />', props: ['form'] },
        'v-skeleton-loader': { template: '<div class="v-skeleton-loader" />' },
        'v-card-title': { template: '<div class="v-card-title"><slot /></div>' },
        'v-card-text': { template: '<div class="v-card-text"><slot /></div>' },
        'v-card-actions': { template: '<div class="v-card-actions"><slot /></div>' },
        'v-spacer': { template: '<span class="v-spacer" />' }
      }
    }
  })

  return { wrapper, showSnackbar }
}

beforeEach(() => {
  jest.clearAllMocks()
  api.get.mockResolvedValue({ data: { people: mockPeople } })
})

afterEach(() => {
  // wrappers unmount automatically with GC but be explicit
})

describe('People.vue', () => {
  describe('initial load', () => {
    it('fetches people on mount', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      expect(api.get).toHaveBeenCalledWith('/people', { params: {} })
    })

    it('renders skeleton loaders while loading', async () => {
      // Don't resolve the promise yet
      let resolve
      api.get.mockReturnValue(new Promise((r) => { resolve = r }))
      const { wrapper } = await mountComponent()
      await nextTick()
      expect(wrapper.findAll('.v-skeleton-loader').length).toBeGreaterThan(0)
      resolve({ data: { people: [] } })
    })

    it('renders a card for each person after load', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      const cards = wrapper.findAll('.v-card')
      // At least one card per person
      expect(cards.length).toBeGreaterThanOrEqual(mockPeople.length)
    })

    it('shows display_name in the list', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.text()).toContain('Alice Smith')
      expect(wrapper.text()).toContain('Bob Jones')
    })

    it('shows "No people found" when list is empty', async () => {
      api.get.mockResolvedValue({ data: { people: [] } })
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.text()).toContain('No people found')
    })

    it('calls showSnackbar on fetch error', async () => {
      api.get.mockRejectedValue({ response: { data: { errors: ['Server error'] } } })
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(showSnackbar).toHaveBeenCalledWith(['Server error'], 'error')
    })
  })

  describe('search', () => {
    it('passes query param when searching', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      jest.clearAllMocks()
      api.get.mockResolvedValue({ data: { people: [mockPeople[0]] } })

      wrapper.vm.searchQuery = 'alice'
      wrapper.vm.debouncedSearch()
      await nextTick()

      expect(api.get).toHaveBeenCalledWith('/people', { params: { query: 'alice' } })
    })

    it('clears query and refetches on clear', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      jest.clearAllMocks()
      api.get.mockResolvedValue({ data: { people: mockPeople } })

      wrapper.vm.searchQuery = 'something'
      wrapper.vm.onClearSearch()
      await nextTick()

      expect(wrapper.vm.searchQuery).toBe('')
      expect(api.get).toHaveBeenCalledWith('/people', { params: {} })
    })
  })

  describe('create dialog', () => {
    it('opens dialog with blank form when New Person is clicked', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()

      wrapper.vm.openCreateDialog()
      await nextTick()

      expect(wrapper.vm.dialogOpen).toBe(true)
      expect(wrapper.vm.editTarget).toBeNull()
      expect(wrapper.vm.form.first_name).toBe('')
    })

    it('posts to /people and shows success on create', async () => {
      api.post.mockResolvedValue({ data: { person: { ...mockPeople[0], id: 3 } } })
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()

      const expectedForm = { first_name: 'New', last_name: 'Person', display_name: 'New Person', email: '', phone: '', title: '', organization_name: '', notes: '' }
      wrapper.vm.form = expectedForm
      await wrapper.vm.createPerson()

      expect(api.post).toHaveBeenCalledWith('/people', { person: expectedForm })
      expect(trackEvent).toHaveBeenCalledWith('created person', { person_id: 3 })
      expect(showSnackbar).toHaveBeenCalledWith(['Person created'], 'success')
      expect(wrapper.vm.dialogOpen).toBe(false)
    })

    it('shows errors from server on failed create', async () => {
      api.post.mockRejectedValue({ response: { data: { errors: ['Display name is required'] } } })
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()

      wrapper.vm.openCreateDialog()
      await wrapper.vm.createPerson()

      expect(showSnackbar).toHaveBeenCalledWith(['Display name is required'], 'error')
      expect(wrapper.vm.dialogOpen).toBe(true)
    })
  })

  describe('edit dialog', () => {
    it('fetches person and opens dialog on edit', async () => {
      api.get
        .mockResolvedValueOnce({ data: { people: mockPeople } })
        .mockResolvedValueOnce({ data: { person: mockPeople[0] } })

      const { wrapper } = await mountComponent()
      await nextTick()

      await wrapper.vm.openEditDialog(mockPeople[0])

      expect(api.get).toHaveBeenCalledWith('/people/1')
      expect(wrapper.vm.dialogOpen).toBe(true)
      expect(wrapper.vm.editTarget).toEqual(mockPeople[0])
      expect(wrapper.vm.form.first_name).toBe('Alice')
    })

    it('patches person and shows success on update', async () => {
      api.patch.mockResolvedValue({ data: { person: mockPeople[0] } })
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()

      wrapper.vm.editTarget = mockPeople[0]
      const expectedForm = { first_name: 'Alice', last_name: 'Smith', display_name: 'Alice Smith Updated', email: '', phone: '', title: '', organization_name: '', notes: '' }
      wrapper.vm.form = expectedForm
      await wrapper.vm.updatePerson()

      expect(api.patch).toHaveBeenCalledWith('/people/1', { person: expectedForm })
      expect(trackEvent).toHaveBeenCalledWith('updated person', { person_id: 1 })
      expect(showSnackbar).toHaveBeenCalledWith(['Person updated'], 'success')
      expect(wrapper.vm.dialogOpen).toBe(false)
    })
  })

  describe('delete', () => {
    it('opens delete confirmation dialog', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()

      wrapper.vm.editTarget = mockPeople[0]
      wrapper.vm.openDeleteDialog()

      expect(wrapper.vm.deleteDialogOpen).toBe(true)
    })

    it('calls DELETE and shows success', async () => {
      api.delete.mockResolvedValue({})
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()

      wrapper.vm.editTarget = mockPeople[0]
      wrapper.vm.dialogOpen = true
      wrapper.vm.deleteDialogOpen = true
      await wrapper.vm.deletePerson()

      expect(api.delete).toHaveBeenCalledWith('/people/1')
      expect(trackEvent).toHaveBeenCalledWith('deleted person', { person_id: 1 })
      expect(showSnackbar).toHaveBeenCalledWith(['Person deleted'], 'success')
      expect(wrapper.vm.deleteDialogOpen).toBe(false)
      expect(wrapper.vm.dialogOpen).toBe(false)
    })

    it('shows error if delete fails', async () => {
      api.delete.mockRejectedValue({ response: { data: { errors: ['Cannot delete'] } } })
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()

      wrapper.vm.editTarget = mockPeople[0]
      await wrapper.vm.deletePerson()

      expect(showSnackbar).toHaveBeenCalledWith(['Cannot delete'], 'error')
    })
  })

  describe('closeDialog', () => {
    it('resets state when dialog is closed', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()

      wrapper.vm.dialogOpen = true
      wrapper.vm.editTarget = mockPeople[0]
      wrapper.vm.form.first_name = 'Edited'
      wrapper.vm.closeDialog()

      expect(wrapper.vm.dialogOpen).toBe(false)
      expect(wrapper.vm.editTarget).toBeNull()
      expect(wrapper.vm.form.first_name).toBe('')
    })
  })
})
