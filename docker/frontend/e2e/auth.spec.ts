import { test, expect } from '@playwright/test';

/**
 * Authentication E2E Tests
 *
 * Tests the complete authentication flow including:
 * - User registration
 * - Login/logout
 * - Password reset
 * - Session management
 * - Security features
 */

test.describe('Authentication Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Clear any existing session
    await page.context().clearCookies();
    await page.evaluate(() => localStorage.clear());
  });

  test('should load landing page and navigate to auth', async ({ page }) => {
    await page.goto('/');

    // Should redirect to landing page
    await expect(page).toHaveURL(/.*landing/);

    // Check ThaliumX branding
    await expect(page.locator('text=ThaliumX')).toBeVisible();

    // Navigate to auth page
    await page.goto('/auth');
    await expect(page.locator('text=Welcome Back')).toBeVisible();
  });

  test('should register new user successfully', async ({ page }) => {
    await page.goto('/auth');

    // Switch to register form
    await page.click('text=Sign up');

    // Fill registration form
    const timestamp = Date.now();
    const testEmail = `testuser${timestamp}@thaliumx.com`;

    await page.fill('input[type="email"]', testEmail);
    await page.fill('input[type="password"]', 'TestPassword123!');
    await page.fill('input[name="firstName"]', 'Test');
    await page.fill('input[name="lastName"]', 'User');

    // Submit registration
    await page.click('button[type="submit"]');

    // Should redirect to dashboard or show success
    await expect(page).toHaveURL(/.*dashboard/);
  });

  test('should login existing user', async ({ page }) => {
    await page.goto('/auth');

    // Use test user created in global setup
    await page.fill('input[type="email"]', 'testuser1@thaliumx.com');
    await page.fill('input[type="password"]', 'TestPassword123!');

    // Submit login
    await page.click('button[type="submit"]');

    // Should redirect to dashboard
    await expect(page).toHaveURL(/.*dashboard/);

    // Check user info in sidebar
    await expect(page.locator('text=Test User')).toBeVisible();
  });

  test('should handle invalid login credentials', async ({ page }) => {
    await page.goto('/auth');

    // Enter wrong credentials
    await page.fill('input[type="email"]', 'invalid@thaliumx.com');
    await page.fill('input[type="password"]', 'wrongpassword');

    await page.click('button[type="submit"]');

    // Should show error message
    await expect(page.locator('text=Invalid credentials')).toBeVisible();
  });

  test('should handle password reset flow', async ({ page }) => {
    await page.goto('/auth');

    // Click forgot password
    await page.click('text=Forgot password?');

    // Fill email for reset
    await page.fill('input[type="email"]', 'testuser1@thaliumx.com');

    // Submit reset request
    await page.click('button[type="submit"]');

    // Should show success message
    await expect(page.locator('text=Password reset email sent')).toBeVisible();
  });

  test('should logout user successfully', async ({ page }) => {
    // First login
    await page.goto('/auth');
    await page.fill('input[type="email"]', 'testuser1@thaliumx.com');
    await page.fill('input[type="password"]', 'TestPassword123!');
    await page.click('button[type="submit"]');
    await expect(page).toHaveURL(/.*dashboard/);

    // Now logout
    await page.click('button:has-text("Sign Out")');

    // Should redirect to auth page
    await expect(page).toHaveURL(/.*auth/);
  });

  test('should protect authenticated routes', async ({ page }) => {
    // Try to access dashboard without authentication
    await page.goto('/dashboard');

    // Should redirect to auth page
    await expect(page).toHaveURL(/.*auth/);
  });

  test('should handle session timeout', async ({ page }) => {
    // Login first
    await page.goto('/auth');
    await page.fill('input[type="email"]', 'testuser1@thaliumx.com');
    await page.fill('input[type="password"]', 'TestPassword123!');
    await page.click('button[type="submit"]');
    await expect(page).toHaveURL(/.*dashboard/);

    // Simulate session expiry by clearing cookies
    await page.context().clearCookies();

    // Try to access protected route
    await page.goto('/dashboard');

    // Should redirect to auth
    await expect(page).toHaveURL(/.*auth/);
  });

  test('should validate email format', async ({ page }) => {
    await page.goto('/auth');

    // Enter invalid email
    await page.fill('input[type="email"]', 'invalid-email');
    await page.fill('input[type="password"]', 'password123');

    await page.click('button[type="submit"]');

    // Should show validation error
    await expect(page.locator('input[type="email"]:invalid')).toBeVisible();
  });

  test('should enforce password requirements', async ({ page }) => {
    await page.goto('/auth');
    await page.click('text=Sign up');

    // Enter weak password
    await page.fill('input[type="email"]', 'test@example.com');
    await page.fill('input[type="password"]', '123');
    await page.fill('input[name="firstName"]', 'Test');
    await page.fill('input[name="lastName"]', 'User');

    await page.click('button[type="submit"]');

    // Should show password validation error
    await expect(page.locator('text=Password must be at least')).toBeVisible();
  });
});