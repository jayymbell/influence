/* eslint-env jest */
import { setActivePinia, createPinia } from 'pinia'

jest.mock('../../src/services/bills', () => ({
  getAll:              jest.fn(),
  get:                 jest.fn(),
  create:              jest.fn(),
  update:              jest.fn(),
  destroy:             jest.fn(),
  linkIssue:           jest.fn(),
  unlinkIssue:         jest.fn(),
  linkClient:          jest.fn(),
  unlinkClient:        jest.fn(),
  addPerson:           jest.fn(),
  removePerson:        jest.fn(),
  getIssueBills:       jest.fn(),
  linkBillToIssue:     jest.fn(),
  unlinkBillFromIssue: jest.fn(),
  search:              jest.fn(),
  importBill:          jest.fn(),
  linkExternal:        jest.fn(),
  refresh:             jest.fn(),
}))

const billsApi = require('../../src/services/bills')
import useBillStore from '../../src/stores/billStore'

const mockBill = {
  id: 1,
  title: 'Test Bill',
  bill_number: 'HB 100',
  status: 'introduced',
  chamber: 'house',
  session_year: 2026,
  tags: [],
  issues: [],
  clients: [],
  people: [],
}

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

describe('BillStore', () => {
  describe('fetchBills', () => {
    it('loads bills into state', async () => {
      billsApi.getAll.mockResolvedValue({ data: { bills: [mockBill] } })
      const store = useBillStore()

      await store.fetchBills()

      expect(billsApi.getAll).toHaveBeenCalledWith({})
      expect(store.bills).toHaveLength(1)
      expect(store.bills[0].title).toBe('Test Bill')
      expect(store.isLoading).toBe(false)
    })

    it('passes params to the API', async () => {
      billsApi.getAll.mockResolvedValue({ data: { bills: [] } })
      const store = useBillStore()

      await store.fetchBills({ status: 'signed', chamber: 'senate' })

      expect(billsApi.getAll).toHaveBeenCalledWith({ status: 'signed', chamber: 'senate' })
    })

    it('sets error state on failure', async () => {
      billsApi.getAll.mockRejectedValue({ response: { data: { errors: ['Forbidden'] } } })
      const store = useBillStore()

      await store.fetchBills()

      expect(store.error).toEqual(['Forbidden'])
      expect(store.bills).toHaveLength(0)
    })
  })

  describe('fetchBill', () => {
    it('loads a single bill into currentBill', async () => {
      billsApi.get.mockResolvedValue({ data: { bill: mockBill } })
      const store = useBillStore()

      await store.fetchBill(1)

      expect(store.currentBill).toEqual(mockBill)
      expect(store.isLoading).toBe(false)
    })

    it('sets error on failure', async () => {
      billsApi.get.mockRejectedValue({ response: { data: { errors: ['Not found'] } } })
      const store = useBillStore()

      await store.fetchBill(99)

      expect(store.error).toEqual(['Not found'])
      expect(store.currentBill).toBeNull()
    })
  })

  describe('createBill', () => {
    it('prepends new bill to state', async () => {
      const newBill = { ...mockBill, id: 2, title: 'New Bill' }
      billsApi.create.mockResolvedValue({ data: { bill: newBill } })
      const store = useBillStore()
      store.bills = [mockBill]

      await store.createBill({ title: 'New Bill', status: 'introduced' })

      expect(store.bills[0].title).toBe('New Bill')
      expect(store.bills).toHaveLength(2)
    })
  })

  describe('updateBill', () => {
    it('replaces updated bill in bills list', async () => {
      const updated = { ...mockBill, title: 'Updated Bill' }
      billsApi.update.mockResolvedValue({ data: { bill: updated } })
      const store = useBillStore()
      store.bills = [mockBill]
      store.currentBill = mockBill

      await store.updateBill(1, { title: 'Updated Bill' })

      expect(store.bills[0].title).toBe('Updated Bill')
      expect(store.currentBill.title).toBe('Updated Bill')
    })

    it('does not error when bill not in list', async () => {
      const updated = { ...mockBill, title: 'Not In List' }
      billsApi.update.mockResolvedValue({ data: { bill: updated } })
      const store = useBillStore()
      store.bills = []
      store.currentBill = null

      const result = await store.updateBill(1, { title: 'Not In List' })

      expect(result.title).toBe('Not In List')
    })
  })

  describe('deleteBill', () => {
    it('removes bill from state', async () => {
      billsApi.destroy.mockResolvedValue({})
      const store = useBillStore()
      store.bills = [mockBill, { ...mockBill, id: 2, title: 'Other' }]

      await store.deleteBill(1)

      expect(store.bills).toHaveLength(1)
      expect(store.bills[0].id).toBe(2)
    })
  })

  describe('linkIssue', () => {
    it('updates issues on currentBill', async () => {
      const issues = [{ id: 3, title: 'Budget', status: 'active' }]
      billsApi.linkIssue.mockResolvedValue({ data: { issues } })
      const store = useBillStore()
      store.currentBill = { ...mockBill }

      await store.linkIssue(1, 3)

      expect(store.currentBill.issues).toEqual(issues)
    })

    it('does not modify currentBill when id does not match', async () => {
      billsApi.linkIssue.mockResolvedValue({ data: { issues: [] } })
      const store = useBillStore()
      store.currentBill = { ...mockBill, id: 99 }

      await store.linkIssue(1, 3)

      expect(store.currentBill.issues).toEqual([])
    })
  })

  describe('unlinkIssue', () => {
    it('updates issues on currentBill after removal', async () => {
      billsApi.unlinkIssue.mockResolvedValue({ data: { issues: [] } })
      const store = useBillStore()
      store.currentBill = { ...mockBill, issues: [{ id: 3, title: 'Budget', status: 'active' }] }

      await store.unlinkIssue(1, 3)

      expect(store.currentBill.issues).toHaveLength(0)
    })
  })

  describe('linkClient', () => {
    it('updates clients on currentBill', async () => {
      const clients = [{ id: 5, display_name: 'Acme' }]
      billsApi.linkClient.mockResolvedValue({ data: { clients } })
      const store = useBillStore()
      store.currentBill = { ...mockBill }

      await store.linkClient(1, 5)

      expect(store.currentBill.clients).toEqual(clients)
    })
  })

  describe('unlinkClient', () => {
    it('updates clients on currentBill after removal', async () => {
      billsApi.unlinkClient.mockResolvedValue({ data: { clients: [] } })
      const store = useBillStore()
      store.currentBill = { ...mockBill, clients: [{ id: 5, display_name: 'Acme' }] }

      await store.unlinkClient(1, 5)

      expect(store.currentBill.clients).toHaveLength(0)
    })
  })

  describe('addPerson', () => {
    it('updates people on currentBill', async () => {
      const people = [{ id: 7, display_name: 'Jane Smith' }]
      billsApi.addPerson.mockResolvedValue({ data: { people } })
      const store = useBillStore()
      store.currentBill = { ...mockBill }

      await store.addPerson(1, 7)

      expect(store.currentBill.people).toEqual(people)
    })
  })

  describe('removePerson', () => {
    it('updates people on currentBill after removal', async () => {
      billsApi.removePerson.mockResolvedValue({ data: { people: [] } })
      const store = useBillStore()
      store.currentBill = { ...mockBill, people: [{ id: 7, display_name: 'Jane Smith' }] }

      await store.removePerson(1, 7)

      expect(store.currentBill.people).toHaveLength(0)
    })
  })

  describe('fetchIssueBills / linkBillToIssue / unlinkBillFromIssue', () => {
    it('fetchIssueBills returns bills array', async () => {
      billsApi.getIssueBills.mockResolvedValue({ data: { bills: [mockBill] } })
      const store = useBillStore()

      const result = await store.fetchIssueBills(10)

      expect(billsApi.getIssueBills).toHaveBeenCalledWith(10)
      expect(result).toHaveLength(1)
    })

    it('linkBillToIssue returns updated bills array', async () => {
      billsApi.linkBillToIssue.mockResolvedValue({ data: { bills: [mockBill] } })
      const store = useBillStore()

      const result = await store.linkBillToIssue(10, 1)

      expect(billsApi.linkBillToIssue).toHaveBeenCalledWith(10, 1)
      expect(result).toHaveLength(1)
    })

    it('unlinkBillFromIssue returns updated bills array', async () => {
      billsApi.unlinkBillFromIssue.mockResolvedValue({ data: { bills: [] } })
      const store = useBillStore()

      const result = await store.unlinkBillFromIssue(10, 1)

      expect(billsApi.unlinkBillFromIssue).toHaveBeenCalledWith(10, 1)
      expect(result).toHaveLength(0)
    })
  })

  describe('searchExternalBills', () => {
    it('calls billsApi.search and returns response data', async () => {
      const mockResults = [{ external_id: 'ocd-bill/1', title: 'Test', already_imported: false }]
      billsApi.search.mockResolvedValue({ data: { results: mockResults } })
      const store = useBillStore()

      const data = await store.searchExternalBills('education', 1)

      expect(billsApi.search).toHaveBeenCalledWith('education', { page: 1 })
      expect(data.results).toHaveLength(1)
    })

    it('propagates errors', async () => {
      billsApi.search.mockRejectedValue({ response: { data: { errors: ['Forbidden'] } } })
      const store = useBillStore()

      await expect(store.searchExternalBills('x')).rejects.toBeTruthy()
    })
  })

  describe('importBill', () => {
    it('prepends newly created bill and returns it', async () => {
      const newBill = { ...mockBill, id: 99, title: 'Imported Bill' }
      billsApi.importBill.mockResolvedValue({ data: { bill: newBill, imported: true } })
      const store = useBillStore()
      store.bills = [mockBill]

      const result = await store.importBill('ocd-bill/99')

      expect(billsApi.importBill).toHaveBeenCalledWith('ocd-bill/99')
      expect(result.id).toBe(99)
      expect(store.bills[0].id).toBe(99)
    })

    it('does not duplicate when bill already exists in state', async () => {
      billsApi.importBill.mockResolvedValue({ data: { bill: mockBill, imported: false } })
      const store = useBillStore()
      store.bills = [mockBill] // already present

      await store.importBill('ocd-bill/1')

      expect(store.bills).toHaveLength(1) // not duplicated
    })
  })

  describe('linkExternal', () => {
    it('updates currentBill with linked bill', async () => {
      const linked = { ...mockBill, external_id: 'ocd-bill/1' }
      billsApi.linkExternal.mockResolvedValue({ data: { bill: linked } })
      const store = useBillStore()
      store.currentBill = { ...mockBill }

      await store.linkExternal(1, 'ocd-bill/1')

      expect(billsApi.linkExternal).toHaveBeenCalledWith(1, 'ocd-bill/1')
      expect(store.currentBill.external_id).toBe('ocd-bill/1')
    })
  })

  describe('refreshBill', () => {
    it('updates currentBill with refreshed data', async () => {
      const refreshed = { ...mockBill, title: 'Updated Title' }
      billsApi.refresh.mockResolvedValue({ data: { bill: refreshed } })
      const store = useBillStore()
      store.currentBill = { ...mockBill }

      await store.refreshBill(1)

      expect(billsApi.refresh).toHaveBeenCalledWith(1)
      expect(store.currentBill.title).toBe('Updated Title')
    })
  })
})
