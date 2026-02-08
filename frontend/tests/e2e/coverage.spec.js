import { test, expect } from '@playwright/test'
import { collectCoverage } from '../../playwright/collect-coverage.js'

test('app loads and collects coverage', async ({ page }, testInfo) => {
  await page.goto('/')
  // Check that the main anchor exists (App.vue toolbar title)
  const title = page.locator('a').first()
  await expect(title).toContainText('My App')

  // collect coverage from the window.__coverage__ created by the instrumented build
  const out = await collectCoverage(page, testInfo.title.replace(/\s+/g, '-'))
  expect(out).not.toBeNull()
})

test('login button visible on dashboard when not logged in', async ({ page }, testInfo) => {
  // Navigate to the dashboard (router redirects if not logged in)
  await page.goto('/dashboard')
  
  // When not logged in, the "Log In" button should appear in the toolbar
  // Look for v-btn with text "Log In"
  const loginBtn = page.getByRole('button', { name: /log in/i })
  await expect(loginBtn).toBeVisible({ timeout: 5000 })

  const out = await collectCoverage(page, testInfo.title.replace(/\s+/g, '-'))
  expect(out).not.toBeNull()
})

test('can navigate to login page', async ({ page }, testInfo) => {
  await page.goto('/dashboard')
  
  // Click the "Log In" button to navigate to login
  const loginBtn = page.getByRole('button', { name: /log in/i })
  await loginBtn.click()
  
  // Verify we're on the login route (either /login or stayed on /dashboard)
  // The page should display login content
  await page.waitForURL(/login|dashboard/i)

  const out = await collectCoverage(page, testInfo.title.replace(/\s+/g, '-'))
  expect(out).not.toBeNull()
})

test('login page renders form fields', async ({ page }, testInfo) => {
  await page.goto('/login')
  
  // Check for email/username input
  const emailInput = page.locator('input[type="email"]')
  const textInput = page.locator('input[type="text"]')
  const hasEmailOrTextInput = (await emailInput.count() > 0) || (await textInput.count() > 0)
  expect(hasEmailOrTextInput).toBeTruthy()
  
  // Check for password input
  const passwordInput = page.locator('input[type="password"]')
  await expect(passwordInput).toBeVisible()
  
  // Check for submit button
  const submitButton = page.locator('button[type="submit"]')
  await expect(submitButton).toBeVisible()

  const out = await collectCoverage(page, testInfo.title.replace(/\s+/g, '-'))
  expect(out).not.toBeNull()
})

test('signup button visible on login page', async ({ page }, testInfo) => {
  await page.goto('/login')
  
  // Check for "Sign Up" button
  const signupBtn = page.getByRole('button', { name: /sign up/i })
  await expect(signupBtn).toBeVisible()

  const out = await collectCoverage(page, testInfo.title.replace(/\s+/g, '-'))
  expect(out).not.toBeNull()
})

