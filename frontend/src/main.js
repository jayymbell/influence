import { createApp } from 'vue'
import { createPinia } from 'pinia'
import './style.css'
import App from './App.vue'
import router from './router'
import vuetify from '../plugins/vuetify'
import '@mdi/font/css/materialdesignicons.css'
import 'vuetify/styles';

const app = createApp(App)
const pinia = createPinia()

app.use(router)
app.use(pinia)
app.use(vuetify)
app.mount('#app')