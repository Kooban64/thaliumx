import { DatabaseService } from '../src/services/database';
import { RedisService } from '../src/services/redis';
import { LoggerService } from '../src/services/logger';
import { beforeAll, afterAll, jest, expect } from '@jest/globals';

// Setup test environment
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-jwt-secret-that-is-at-least-32-characters-long';
process.env.ENCRYPTION_KEY = 'test-encryption-key-that-is-at-least-32-chars';
process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/test_db';
process.env.REDIS_URL = 'redis://localhost:6379/1';

// Some services use discrete DB_* env vars instead of DATABASE_URL
process.env.DB_HOST = process.env.DB_HOST || 'localhost';
process.env.DB_PORT = process.env.DB_PORT || '5432';
process.env.DB_NAME = process.env.DB_NAME || 'test_db';
process.env.DB_USER = process.env.DB_USER || 'test';
process.env.DB_PASSWORD = process.env.DB_PASSWORD || 'test';

// Global test setup
beforeAll(async () => {
  // Initialize minimal services for testing
  try {
    LoggerService.initialize();
    // Note: Database and Redis initialization skipped in unit tests
    // Use integration tests for full service testing
  } catch (error) {
    console.warn('Test setup warning:', error);
  }
});

afterAll(async () => {
  // Cleanup
  try {
    await RedisService.close();
    await DatabaseService.close();
  } catch (error) {
    console.warn('Test cleanup warning:', error);
  }
});

// Mock external dependencies
jest.mock('../src/services/email', () => ({
  EmailService: {
    initialize: jest.fn(),
    sendPasswordReset: jest.fn()
  }
}));

jest.mock('../src/services/kafka', () => ({
  KafkaService: {
    initialize: jest.fn(),
    produce: jest.fn(),
    close: jest.fn()
  }
}));

// Custom matchers
expect.extend({
  toBeValidUUID(received) {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    const pass = uuidRegex.test(received);
    return {
      message: () => `expected ${received} to be a valid UUID`,
      pass
    };
  }
});
