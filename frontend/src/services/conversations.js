import api from './api'

const conversationsApi = {
  /**
   * GET /conversations
   */
  getAll() {
    return api.get('/conversations')
  },

  /**
   * GET /conversations/:id
   */
  get(id) {
    return api.get(`/conversations/${id}`)
  },

  /**
   * POST /conversations
   */
  create(data = {}) {
    return api.post('/conversations', { conversation: data })
  },

  /**
   * PATCH /conversations/:id
   */
  update(id, data) {
    return api.patch(`/conversations/${id}`, { conversation: data })
  },

  /**
   * DELETE /conversations/:id
   */
  destroy(id) {
    return api.delete(`/conversations/${id}`)
  },

  /**
   * POST /conversations/:id/messages
   */
  sendMessage(id, content) {
    return api.post(`/conversations/${id}/messages`, { message: { content } })
  },
}

export default conversationsApi
