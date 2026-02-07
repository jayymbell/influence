import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vuetify from 'vite-plugin-vuetify'
import istanbul from 'vite-plugin-istanbul'

// Enable coverage instrumentation when VITE_COVERAGE=true
const enableCoverage = process.env.VITE_COVERAGE === 'true'

export default defineConfig({
  plugins: [
    vue(),
    vuetify({
      autoImport: true,
    }),
    enableCoverage && istanbul({
      include: ['src/**/*.js', 'src/**/*.vue', 'src/**/*.ts'],
      extension: ['.js', '.ts', '.vue'],
      // produce `window.__coverage__` for collection by Playwright
      requireEnv: false,
    })
  ].filter(Boolean),
});
