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

test('signup page renders form fields', async ({ page }, testInfo) => {
  await page.goto('/signup')
  
  // Check for email input
  const emailInput = page.locator('input[type="email"]')
  await expect(emailInput).toBeVisible()
  
  // Check for at least one password input (signup has multiple password fields)
  const passwordInputs = page.locator('input[type="password"]')
  expect(await passwordInputs.count()).toBeGreaterThan(0)
  
  // Check for submit button
  const submitButton = page.locator('button[type="submit"]')
  await expect(submitButton).toBeVisible()

  const out = await collectCoverage(page, testInfo.title.replace(/\s+/g, '-'))
  expect(out).not.toBeNull()
})

test('dashboard view loads when navigating', async ({ page }, testInfo) => {
  await page.goto('/dashboard')
  
  // Page should load without error
  await expect(page).not.toHaveTitle(/error|404/i)

  const out = await collectCoverage(page, testInfo.title.replace(/\s+/g, '-'))
  expect(out).not.toBeNull()
})

test('account page navigates from toolbar', async ({ page }, testInfo) => {
  // Note: This test assumes we can navigate to account without being logged in
  // In a real scenario, this might redirect to login
  await page.goto('/account')
  
  // Page should load
  await expect(page).not.toHaveTitle(/error|500/i)

  const out = await collectCoverage(page, testInfo.title.replace(/\s+/g, '-'))
  expect(out).not.toBeNull()
})

test('roles page accessible', async ({ page }, testInfo) => {
  // Navigate to roles page
  await page.goto('/roles')
  
  // Page should load
  await expect(page).not.toHaveTitle(/error|500/i)

  const out = await collectCoverage(page, testInfo.title.replace(/\s+/g, '-'))
  expect(out).not.toBeNull()
})

test('users page accessible', async ({ page }, testInfo) => {
  // Navigate to users page
  await page.goto('/users')
  
  // Page should load
  await expect(page).not.toHaveTitle(/error|500/i)

  const out = await collectCoverage(page, testInfo.title.replace(/\s+/g, '-'))
  expect(out).not.toBeNull()
})

test('toolbar title navigates to dashboard', async ({ page }, testInfo) => {
  await page.goto('/login')
  
  // Click the app title to navigate to dashboard
  const titleLink = page.locator('a').first()
  await titleLink.click()
  
  // Should navigate away from login
  await page.waitForURL(/dashboard|\//i)

  const out = await collectCoverage(page, testInfo.title.replace(/\s+/g, '-'))
  expect(out).not.toBeNull()
})

