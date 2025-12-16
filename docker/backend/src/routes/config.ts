/**
 * Configuration API Routes
 *
 * Exposes configurable settings to the frontend including:
 * - Currency configuration (symbol, code, locale)
 * - KYC level limits
 * - Role transaction limits
 */

import { Router, Request, Response } from 'express';
import { kycLimitsConfig, getCurrencySymbol, getCurrencyCode, formatCurrency } from '../config/kyc-limits.config';
import { KYCService } from '../services/kyc';
import { RBACService } from '../services/rbac';
import { LoggerService } from '../services/logger';

const router: Router = Router();

/**
 * GET /api/config/currency
 * Returns currency configuration for the platform
 */
router.get('/currency', async (req: Request, res: Response): Promise<void> => {
  try {
    kycLimitsConfig.initialize();
    const currency = kycLimitsConfig.getCurrency();

    res.json({
      success: true,
      data: {
        code: currency.code,
        symbol: currency.symbol,
        name: currency.name,
        decimals: currency.decimals,
        locale: currency.locale
      }
    });
  } catch (error: any) {
    LoggerService.error('Failed to get currency config:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to retrieve currency configuration'
    });
  }
});

/**
 * GET /api/config/kyc-limits
 * Returns KYC level limits for all levels
 */
router.get('/kyc-limits', async (req: Request, res: Response): Promise<void> => {
  try {
    kycLimitsConfig.initialize();
    const allConfigs = kycLimitsConfig.getAllKYCLevelConfigs();
    const currency = kycLimitsConfig.getCurrency();

    // Format limits with currency information
    const formattedLimits: Record<string, any> = {};

    for (const [level, config] of Object.entries(allConfigs)) {
      formattedLimits[level] = {
        name: config.name,
        description: config.description,
        requirements: config.requirements,
        limits: {
          maxInvestment: config.limits.maxInvestment,
          maxTrading: config.limits.maxTrading,
          maxWithdrawal: config.limits.maxWithdrawal,
          maxDeposit: config.limits.maxDeposit,
          maxDailyTransactions: config.limits.maxDailyTransactions,
          // Formatted versions for display
          maxInvestmentFormatted: formatCurrency(config.limits.maxInvestment),
          maxTradingFormatted: formatCurrency(config.limits.maxTrading),
          maxWithdrawalFormatted: formatCurrency(config.limits.maxWithdrawal),
          maxDepositFormatted: config.limits.maxDeposit ? formatCurrency(config.limits.maxDeposit) : null
        },
        checks: {
          sanctionsCheck: config.sanctionsCheck,
          pepCheck: config.pepCheck,
          faceVerification: config.faceVerification,
          ongoingMonitoring: config.ongoingMonitoring
        }
      };
    }

    res.json({
      success: true,
      data: {
        currency: {
          code: currency.code,
          symbol: currency.symbol
        },
        levels: formattedLimits
      }
    });
  } catch (error: any) {
    LoggerService.error('Failed to get KYC limits:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to retrieve KYC limits'
    });
  }
});

export default router;