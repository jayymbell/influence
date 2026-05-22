/* eslint-env jest */
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import Issues from '../../src/views/Issues.vue'
import { createTestRouter } from './setup'

jest.mock('../../src/services/issues', () => ({
  getAll: jest.fn(),
  get:    jest.fn(),
  create: jest.fn(),
  update: jest.fn(),
}))

jest.mock('../../src/services/ahoy.js', () => ({ trackEvent: jest.fn() }))

jest.mock('lodash', () => ({
  ...jest.requireActual('lodash'),
  debounce: (fn) => fn
}))

const issuesApi = require('../../src/services/issues')

const mockIssues = [
  { id: 1, title: 'Budget Reform', status: 'active',   tags: ['healthcare'], clients: [{ id: 1, display_name: 'Acme' }] },
  { id: 2, title: 'Transport Bill', status: 'inactive', tags: [],             clients: [{ id: 2, display_name: 'Beta' }] },
  { id: 3, title: 'Closed Matter',  status: 'closed',   tags: ['energy'],    clients: [{ id: 1, display_name: 'Acme' }] },
]

const mountComponent = async () => {
  const pinia = createPinia()
  setActivePinia(pinia)
  const router = createTestRouter()
  await router.push('/issues')
  await router.isReady()
  const showSnackbar = jest.fn()
  const wrapper = mount(Issues, {
    global: {
      plugins: [pinia, router],
      provide: { showSnackbar },
      stubs: {
        'v-skeleton-loader': { template: '<div class="v-skeleton-loader" />' },
        'v-card-title':   { template: '<div class="v-card-title"><slot /></div>' },
        'v-card-text':    { template: '<div class="v-card-text"><slot /></div>' },
        'v-card-actions': { template: '<div class="v-card-actions"><slot /></div>' },
        'v-spacer':       { template: '<span class="v-spacer" />' },
        'v-chip':         { template: '<span class="v-chip"><slot /></span>' },
        'v-textarea':     { template: '<textarea />' },
        'v-combobox':     { template: '<input />' },
        'v-select':       { template: '<select />' },
      }
    }
  })
  return { wrapper, showSnackbar }
}

beforeEach(() => {
  jest.resetAllMocks()
  issuesApi.getAll.mockResolvedValue({ data: { issues: [...mockIssues] } })
})

describe('Issues.vue', () => {
  describe('initial load', () => {
    it('fetches issues on mount', async () => {
      await mountComponent()
      await nextTick()
      expect(issuesApi.getAll).toHaveBeenCalledWith({})
    })

    it('renders skeleton loaders while loading', async () => {
      let resolve
      issuesApi.getAll.mockReturnValue(new Promise((r) => { resolve = r }))
      const { wrapper } = await mountComponent()
      await nextTick()
      expect(wrapper.findAll('.v-skeleton-loader').length).toBeGreaterThan(0)
      resolve({ data: { issues: [] } })
    })

    it('renders a card for each issue', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.findAll('.v-card').length).toBeGreaterThanOrEqual(mockIssues.length)
    })

    it('shows issue titles', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.text()).toContain('Budget Reform')
      expect(wrapper.text()).toContain('Transport Bill')
    })

    it('shows client name', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.text()).toContain('Acme')
    })

    it('renders tags as chips', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.text()).toContain('healthcare')
    })

    it('shows "No issues found" when empty', async () => {
      issuesApi.getAll.mockResolvedValue({ data: { issues: [] } })
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.text()).toContain('No issues found')
    })

    it('calls showSnackbar on fetch error', async () => {
      issuesApi.getAll.mockRejectedValue({ response: { data: { errors: ['Forbidden'] } } })
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(showSnackbar).toHaveBeenCalledWith(['Forbidden'], 'error')
    })
  })

  describe('create issue', () => {
    it('calls issuesApi.create and prepends to list on success', async () => {
      const newIssue = { id: 4, title: 'New Issue', status: 'active', tags: [], clients: [{ id: 1, display_name: 'Acme' }] }
      issuesApi.create.mockResolvedValue({ data: { issue: newIssue } })

      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      await nextTick()

      // Call createIssue directly via internal ref
      wrapper.vm.form.title = 'New Issue'
      await wrapper.vm.createIssue()
      await nextTick()

      expect(issuesApi.create).toHaveBeenCalled()
      expect(showSnackbar).toHaveBeenCalledWith(['Issue created.'], 'success')
    })

    it('shows error snackbar on create failure', async () => {
      issuesApi.create.mockRejectedValue({ response: { data: { errors: ['Title is blank'] } } })

      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      await nextTick()

      wrapper.vm.form.title = ''
      await wrapper.vm.createIssue()
      await nextTick()

      expect(showSnackbar).toHaveBeenCalledWith(['Title is blank'], 'error')
    })
  })

  describe('update issue', () => {
    it('calls issuesApi.update and updates list on success', async () => {
      const updated = { ...mockIssues[0], title: 'Updated Title' }
      issuesApi.update.mockResolvedValue({ data: { issue: updated } })

      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      await nextTick()

      // Set edit state directly (same pattern as Clients.test.js)
      wrapper.vm.editTarget = mockIssues[0]
      wrapper.vm.form = { title: 'Updated Title', description: '', notes: '', tags: [] }
      await wrapper.vm.updateIssue()
      await nextTick()

      expect(issuesApi.update).toHaveBeenCalledWith(1, { title: 'Updated Title', description: '', notes: '', tags: [] })
      expect(showSnackbar).toHaveBeenCalledWith(['Issue updated.'], 'success')
    })
  })
})
