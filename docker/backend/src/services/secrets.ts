/**
 * Secrets Service (AWS Secrets Manager)
 * 
 * Integration with AWS Secrets Manager for secure secret storage and retrieval.
 * 
 * Features:
 * - Retrieve secrets from AWS Secrets Manager
 * - Support for both string and binary secrets
 * - Automatic secret rotation (handled by AWS)
 * - Region-based secret access
 * 
 * Usage:
 * - Primary secret storage for production environments
 * - Falls back to .secrets files or environment variables
 * - Used by ConfigService for secret loading
 * 
 * Security:
 * - Secrets never logged
 * - Encrypted at rest by AWS
 * - IAM-based access control
 * - Audit logging via CloudTrail
 * 
 * Configuration:
 * - AWS_REGION: AWS region for Secrets Manager (default: us-east-1)
 * - Requires AWS credentials configured (IAM role, credentials file, or environment)
 */

import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';
import { LoggerService } from './logger';

export class SecretsService {
  private static client = new SecretsManagerClient({ region: process.env.AWS_REGION || 'us-east-1' });

  public static async getSecret(secretName: string): Promise<string> {
    try {
      const response = await this.client.send(
        new GetSecretValueCommand({ SecretId: secretName })
      );
      if (response.SecretString) {
        return response.SecretString;
      } else if (response.SecretBinary) {
        return Buffer.from(response.SecretBinary).toString('utf8');
      }
      throw new Error(`Secret ${secretName} is empty`);
    } catch (error) {
      LoggerService.error(`Failed to get secret ${secretName}`, error);
      throw error;
    }
  }

  // For rotation, AWS handles it automatically for supported services
  // We can trigger rotation if needed via RotateSecretCommand
}