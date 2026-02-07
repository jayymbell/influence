const { devices } = require('@playwright/test')

/** @type {import('@playwright/test').PlaywrightTestConfig} */
module.exports = {
  testDir: '../tests/e2e',
  timeout: 30 * 1000,
  use: {
    baseURL: 'http://localhost:5173',
    headless: true,
    viewport: { width: 1280, height: 720 }
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } }
  ]
}
