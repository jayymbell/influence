import {computed, ref} from 'vue'
import {defineStore} from 'pinia'
import api from '../services/api'
import { trackEvent } from "../services/ahoy.js";


const useUserStore = defineStore("UserStore", () => {
    
    // state
    const user = ref(JSON.parse(localStorage.getItem('user')))
    const bearerToken = ref(localStorage.getItem('bearerToken'))

    // getters
    const isLoggedIn = computed(() => bearerToken.value !== null)

    const hasRole = (roleName) => {
        if (!user.value || !user.value.roles) return false;
        return user.value.roles.map(item => item.name).includes(roleName);
    }

    //actions

    const login = async (data) => {
        const response = await api.post(`/login`, data)
        bearerToken.value = response.data.token
        localStorage.setItem('bearerToken', bearerToken.value)
        user.value = response.data.user
        localStorage.setItem('user', JSON.stringify(user.value))
         api.defaults.headers.common['Authorization'] = `Bearer ${bearerToken.value}`

        return response
    }

    const logout = async () => {
        trackEvent("Logged out", {})
        bearerToken.value = null
        user.value = null
        localStorage.removeItem('bearerToken')
        localStorage.removeItem('user')

        const response = await api.delete(`/logout`)


        return response
    }

    const update = async (data) => {
        const response = await api.patch(`/signup`, data)
        user.value = response.data.user
        localStorage.setItem('user', JSON.stringify(user.value))
        return response 
    }
    

    

    return {user, bearerToken, isLoggedIn, login, logout, update, hasRole}
})

export default useUserStore