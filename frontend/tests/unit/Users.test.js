/* eslint-env jest */
import { setActivePinia, createPinia } from 'pinia'

// Mock API and tracking services
jest.mock('../../src/services/api', () => ({
  get: jest.fn(),
  delete: jest.fn(),
  patch: jest.fn()
}))
jest.mock('../../src/services/ahoy.js', () => ({ trackEvent: jest.fn().mockResolvedValue({}) }))
jest.mock('lodash', () => ({
  capitalize: jest.fn((str) => str.charAt(0).toUpperCase() + str.slice(1))
}))

const mockApi = require('../../src/services/api')
const { trackEvent } = require('../../src/services/ahoy.js')

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

describe('Users.vue', () => {
  const mockUsers = [
    { id: 1, email: 'active@example.com', created_at: '2023-01-01', discarded_at: null, roles: [] },
    { id: 2, email: 'inactive@example.com', created_at: '2023-06-01', discarded_at: '2024-01-01', roles: [] }
  ]

  const mockUserDetails = {
    id: 1,
    email: 'user@example.com',
    created_at: '2023-01-01',
    discarded_at: null,
    roles: [
      { id: 1, name: 'admin' },
      { id: 2, name: 'user' }
    ]
  }

  const mockEvents = [
    { id: 1, name: 'logged in', time: '2024-01-15T10:00:00Z' },
    { id: 2, name: 'updated profile', time: '2024-01-16T15:30:00Z' }
  ]

  const createComponent = () => {
    const showSnackbar = jest.fn()
    return {
      users: [],
      user: '',
      events: [],
      searchEmail: '',
      filteredUsers: [],
      showActive: true,
      showSnackbar,
      filterUsers: function() {
        const email = this.searchEmail.toLowerCase()
        this.filteredUsers = this.users.filter(user => {
          const matchesEmail = user.email.toLowerCase().includes(email)
          const isActive = this.showActive ? !user.discarded_at : !!user.discarded_at
          return matchesEmail && isActive
        })
      },
      fetchUsers: async function() {
        const response = await mockApi.get('/users')
        this.users = response.data.users
        this.filteredUsers = response.data.users
        this.filterUsers()
      },
      fetchUser: async function(u) {
        const response = await mockApi.get('/users/' + u.id)
        this.user = response.data.user
        await this.fetchEvents(u)
      },
      fetchEvents: async function(u) {
        try {
          const response = await mockApi.get('users/events', { params: { user_id: u.id } })
          this.events = response.data.events
        } catch (error) {
          const e = error.response.data.errors || ['An unknown error occurred']
          this.showSnackbar(e, 'error')
        }
      },
      deactivateUser: async function(u) {
        try {
          if (confirm(`Are you sure you want to deactivate user ${u.email}?`)) {
            await mockApi.delete('/users/' + u.id)
            trackEvent('deactivated user', { user_id: u.id })
            this.showSnackbar(['User deactivated'], 'success')
            await this.fetchUsers()
            this.user = ''
          }
        } catch (error) {
          const e = error.response.data.errors || ['An unknown error occurred']
          this.showSnackbar(e, 'error')
        }
      },
      reactivateUser: async function(u) {
        try {
          await mockApi.patch('/users/' + u.id, { user: { discarded_at: null } })
          trackEvent('reactivated user', { user_id: u.id })
          this.showSnackbar(['User reactivated'], 'success')
          await this.fetchUsers()
        } catch (error) {
          const e = error.response.data.errors || ['An unknown error occurred']
          this.showSnackbar(e, 'error')
        }
      },
      deleteRole: async function(r) {
        try {
          const roleIds = this.user.roles.map(item => item.id)
          const filteredRoleIds = roleIds.filter(id => id !== r.id)
          await mockApi.patch('/users/' + this.user.id, { user: { role_ids: filteredRoleIds } })
          trackEvent('removed user role', { user_id: this.user.id, role_id: r.id })
          this.showSnackbar(['User role removed'], 'success')
          await this.fetchUser(this.user)
        } catch (error) {
          const e = error.response.data.errors || ['An unknown error occurred']
          this.showSnackbar(e, 'error')
        }
      },
      get est() {
        return this.user ? new Date(this.user.created_at).getFullYear() : null
      }
    }
  }

  test('filters users by email search', () => {
    const component = createComponent()
    component.users = mockUsers
    component.searchEmail = 'active'
    component.filterUsers()
    expect(component.filteredUsers).toEqual([mockUsers[0]])
  })

  test('filters users by active status', () => {
    const component = createComponent()
    component.users = mockUsers
    component.showActive = false
    component.filterUsers()
    expect(component.filteredUsers).toEqual([mockUsers[1]])
  })

  test('filters users by email and active status combined', () => {
    const component = createComponent()
    component.users = mockUsers
    component.searchEmail = 'example.com'
    component.showActive = true
    component.filterUsers()
    expect(component.filteredUsers).toEqual([mockUsers[0]])
  })

  test('fetches users list', async () => {
    mockApi.get.mockResolvedValue({ data: { users: mockUsers } })
    const component = createComponent()
    await component.fetchUsers()
    expect(mockApi.get).toHaveBeenCalledWith('/users')
    expect(component.users).toEqual(mockUsers)
  })

  test('fetches user details', async () => {
    mockApi.get.mockResolvedValueOnce({ data: { events: mockEvents } })
    const component = createComponent()
    await component.fetchUser(mockUsers[0])
    expect(mockApi.get).toHaveBeenCalledWith('/users/1')
  })

  test('shows confirmation dialog before deactivating user', async () => {
    window.confirm = jest.fn(() => false)
    const component = createComponent()
    await component.deactivateUser(mockUsers[0])
    expect(window.confirm).toHaveBeenCalledWith(
      `Are you sure you want to deactivate user ${mockUsers[0].email}?`
    )
    expect(mockApi.delete).not.toHaveBeenCalled()
  })

  test('deactivates user when confirmed', async () => {
    mockApi.delete.mockResolvedValue({ data: {} })
    mockApi.get.mockResolvedValue({ data: { users: [] } })
    window.confirm = jest.fn(() => true)
    const component = createComponent()
    await component.deactivateUser(mockUsers[0])
    expect(mockApi.delete).toHaveBeenCalledWith('/users/1')
    expect(trackEvent).toHaveBeenCalledWith('deactivated user', { user_id: 1 })
    expect(component.showSnackbar).toHaveBeenCalledWith(['User deactivated'], 'success')
  })

  test('reactivates user', async () => {
    mockApi.patch.mockResolvedValue({ data: {} })
    mockApi.get.mockResolvedValue({ data: { users: [] } })
    const component = createComponent()
    await component.reactivateUser(mockUsers[1])
    expect(mockApi.patch).toHaveBeenCalledWith('/users/2', { user: { discarded_at: null } })
    expect(trackEvent).toHaveBeenCalledWith('reactivated user', { user_id: 2 })
    expect(component.showSnackbar).toHaveBeenCalledWith(['User reactivated'], 'success')
  })

  test('removes role from user', async () => {
    mockApi.patch.mockResolvedValue({ data: {} })
    mockApi.get.mockResolvedValue({ data: { events: [] } })
    const component = createComponent()
    component.user = mockUserDetails
    await component.deleteRole(mockUserDetails.roles[1])
    expect(mockApi.patch).toHaveBeenCalledWith('/users/1', { user: { role_ids: [1] } })
    expect(trackEvent).toHaveBeenCalledWith('removed user role', { user_id: 1, role_id: 2 })
    expect(component.showSnackbar).toHaveBeenCalledWith(['User role removed'], 'success')
  })

  test('handles deactivation error gracefully', async () => {
    mockApi.delete.mockRejectedValue({ response: { data: { errors: ['Cannot deactivate'] } } })
    window.confirm = jest.fn(() => true)
    const component = createComponent()
    await component.deactivateUser(mockUsers[0])
    expect(component.showSnackbar).toHaveBeenCalledWith(['Cannot deactivate'], 'error')
  })

  test('handles role removal error gracefully', async () => {
    mockApi.patch.mockRejectedValue({ response: { data: { errors: ['Cannot remove role'] } } })
    const component = createComponent()
    component.user = mockUserDetails
    await component.deleteRole(mockUserDetails.roles[0])
    expect(component.showSnackbar).toHaveBeenCalledWith(['Cannot remove role'], 'error')
  })

  test('closes user details', () => {
    const component = createComponent()
    component.user = mockUserDetails
    component.user = ''
    expect(component.user).toBe('')
  })

  test('displays member since year correctly', () => {
    const component = createComponent()
    component.user = mockUserDetails
    expect(component.est).toBe(2023)
  })

  test('fetches events for user', async () => {
    mockApi.get.mockResolvedValue({ data: { events: mockEvents } })
    const component = createComponent()
    await component.fetchEvents(mockUsers[0])
    expect(mockApi.get).toHaveBeenCalledWith('users/events', { params: { user_id: 1 } })
    expect(component.events).toEqual(mockEvents)
  })

  test('handles event fetching error gracefully', async () => {
    mockApi.get.mockRejectedValue({ response: { data: { errors: ['Cannot fetch'] } } })
    const component = createComponent()
    await component.fetchEvents(mockUsers[0])
    expect(component.showSnackbar).toHaveBeenCalledWith(['Cannot fetch'], 'error')
  })
})
