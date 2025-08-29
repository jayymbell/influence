import { createApp } from 'vue'
import { createPinia } from 'pinia'
import './style.css'
import App from './App.vue'
import vuetify from '../plugins/vuetify'

const app = createApp(App)

const pinia = createPinia()
app.use(pinia)

app.use(vuetify)

app.mount('#app')