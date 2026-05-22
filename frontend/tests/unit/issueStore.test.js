/* eslint-env jest */
import { setActivePinia, createPinia } from 'pinia'

jest.mock('../../src/services/issues', () => ({
  getAll:            jest.fn(),
  get:               jest.fn(),
  create:            jest.fn(),
  update:            jest.fn(),
  destroy:           jest.fn(),
  close:             jest.fn(),
  deactivate:        jest.fn(),
  reactivate:        jest.fn(),
  shareWithClient:   jest.fn(),
  unshareFromClient: jest.fn(),
  addPerson:         jest.fn(),
  removePerson:      jest.fn(),
}))

const issuesApi = require('../../src/services/issues')
import useIssueStore from '../../src/stores/issueStore'

const mockIssue = {
  id: 1,
  title: 'Test Issue',
  status: 'active',
  tags: [],
  client: { id: 1, display_name: 'Acme' },
  people: [],
  shared_clients: [],
}

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

describe('IssueStore', () => {
  describe('fetchIssues', () => {
    it('loads issues into state', async () => {
      issuesApi.getAll.mockResolvedValue({ data: { issues: [mockIssue] } })
      const store = useIssueStore()

      await store.fetchIssues()

      expect(issuesApi.getAll).toHaveBeenCalledWith({})
      expect(store.issues).toHaveLength(1)
      expect(store.issues[0].title).toBe('Test Issue')
      expect(store.isLoading).toBe(false)
    })

    it('passes params to the API', async () => {
      issuesApi.getAll.mockResolvedValue({ data: { issues: [] } })
      const store = useIssueStore()

      await store.fetchIssues({ status: 'active', query: 'budget' })

      expect(issuesApi.getAll).toHaveBeenCalledWith({ status: 'active', query: 'budget' })
    })

    it('sets error state on failure', async () => {
      issuesApi.getAll.mockRejectedValue({ response: { data: { errors: ['Forbidden'] } } })
      const store = useIssueStore()

      await store.fetchIssues()

      expect(store.error).toEqual(['Forbidden'])
      expect(store.issues).toHaveLength(0)
    })
  })

  describe('fetchIssue', () => {
    it('loads a single issue into currentIssue', async () => {
      issuesApi.get.mockResolvedValue({ data: { issue: mockIssue } })
      const store = useIssueStore()

      await store.fetchIssue(1)

      expect(store.currentIssue).toEqual(mockIssue)
      expect(store.isLoading).toBe(false)
    })
  })

  describe('createIssue', () => {
    it('prepends new issue to state', async () => {
      const newIssue = { ...mockIssue, id: 2, title: 'New Issue' }
      issuesApi.create.mockResolvedValue({ data: { issue: newIssue } })
      const store = useIssueStore()
      store.issues = [mockIssue]

      await store.createIssue({ title: 'New Issue', client_id: 1 })

      expect(store.issues[0].title).toBe('New Issue')
      expect(store.issues).toHaveLength(2)
    })
  })

  describe('updateIssue', () => {
    it('replaces updated issue in issues list', async () => {
      const updated = { ...mockIssue, title: 'Updated' }
      issuesApi.update.mockResolvedValue({ data: { issue: updated } })
      const store = useIssueStore()
      store.issues = [mockIssue]
      store.currentIssue = mockIssue

      await store.updateIssue(1, { title: 'Updated' })

      expect(store.issues[0].title).toBe('Updated')
      expect(store.currentIssue.title).toBe('Updated')
    })
  })

  describe('closeIssue', () => {
    it('updates status in list and currentIssue', async () => {
      const closed = { ...mockIssue, status: 'closed', closed_at: '2026-05-01T00:00:00Z' }
      issuesApi.close.mockResolvedValue({ data: { issue: closed } })
      const store = useIssueStore()
      store.issues = [mockIssue]
      store.currentIssue = mockIssue

      await store.closeIssue(1)

      expect(store.currentIssue.status).toBe('closed')
      expect(store.issues[0].status).toBe('closed')
    })
  })

  describe('reactivateIssue', () => {
    it('updates status to active', async () => {
      const reactivated = { ...mockIssue, status: 'active', closed_at: null }
      issuesApi.reactivate.mockResolvedValue({ data: { issue: reactivated } })
      const store = useIssueStore()
      store.currentIssue = { ...mockIssue, status: 'closed' }
      store.issues = [{ ...mockIssue, status: 'closed' }]

      await store.reactivateIssue(1)

      expect(store.currentIssue.status).toBe('active')
    })
  })

  describe('shareWithClient', () => {
    it('updates shared_clients on currentIssue', async () => {
      const clients = [{ id: 2, display_name: 'Beta Corp', is_primary: false }]
      issuesApi.shareWithClient.mockResolvedValue({ data: { clients } })
      const store = useIssueStore()
      store.currentIssue = { ...mockIssue }

      await store.shareWithClient(1, 2)

      expect(store.currentIssue.shared_clients).toEqual(clients)
    })
  })

  describe('addPerson', () => {
    it('updates people on currentIssue', async () => {
      const people = [{ id: 5, display_name: 'Jane Smith', title: 'Director', organization_name: 'Acme', email: 'jane@example.com' }]
      issuesApi.addPerson.mockResolvedValue({ data: { people } })
      const store = useIssueStore()
      store.currentIssue = { ...mockIssue }

      await store.addPerson(1, 5)

      expect(store.currentIssue.people).toEqual(people)
    })
  })

  describe('removePerson', () => {
    it('updates people after removal', async () => {
      issuesApi.removePerson.mockResolvedValue({ data: { people: [] } })
      const store = useIssueStore()
      store.currentIssue = { ...mockIssue, people: [{ id: 5, display_name: 'Jane', title: null, organization_name: null, email: null }] }

      await store.removePerson(1, 5)

      expect(store.currentIssue.people).toHaveLength(0)
    })
  })
})
