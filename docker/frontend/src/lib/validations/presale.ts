import { z } from 'zod';

// USDT amount validation for presale
export const usdtAmountSchema = z
  .string()
  .min(1, 'Amount is required')
  .refine(
    (val) => {
      const num = parseFloat(val);
      return !isNaN(num) && num >= 50 && num <= 100000; // Min $50, Max $100K
    },
    'Amount must be between $50 and $100,000'
  )
  .refine(
    (val) => {
      const parts = val.split('.');
      return parts.length <= 2 && (!parts[1] || parts[1].length <= 2); // Max 2 decimal places for USD
    },
    'Amount cannot have more than 2 decimal places'
  );

// Presale ID validation
export const presaleIdSchema = z
  .string()
  .min(1, 'Presale ID is required')
  .max(100, 'Presale ID is too long')
  .regex(/^[a-zA-Z0-9_-]+$/, 'Presale ID contains invalid characters');

// Wallet address validation (Ethereum)
export const ethereumAddressSchema = z
  .string()
  .min(42, 'Ethereum address is too short')
  .max(42, 'Ethereum address is too long')
  .regex(/^0x[a-fA-F0-9]{40}$/, 'Invalid Ethereum address format');

// Broker code validation
export const brokerCodeSchema = z
  .string()
  .max(50, 'Broker code is too long')
  .regex(/^[A-Z0-9_-]*$/, 'Broker code contains invalid characters')
  .optional();

// Payment method validation
export const paymentMethodSchema = z.enum(['USDT', 'BANK_TRANSFER']);

// Tier validation
export const tierSchema = z.enum(['bronze', 'silver', 'gold', 'platinum']);

// Token purchase validation schema
export const tokenPurchaseSchema = z.object({
  presaleId: presaleIdSchema,
  amount: usdtAmountSchema,
  paymentMethod: paymentMethodSchema,
  walletAddress: ethereumAddressSchema.optional(),
  brokerCode: brokerCodeSchema,
  tier: tierSchema,
}).refine(
  (data) => {
    // If payment method is USDT, wallet address is required
    if (data.paymentMethod === 'USDT') {
      return data.walletAddress && data.walletAddress.length > 0;
    }
    return true;
  },
  {
    message: 'Wallet address is required for USDT payments',
    path: ['walletAddress'],
  }
);

// Investment validation schema (for portfolio display)
export const investmentSchema = z.object({
  id: z.string().uuid('Invalid investment ID'),
  presaleId: presaleIdSchema,
  amount: usdtAmountSchema,
  tokenAmount: z.string().refine(
    (val) => {
      const num = parseFloat(val);
      return !isNaN(num) && num > 0;
    },
    'Invalid token amount'
  ),
  status: z.enum(['pending', 'confirmed', 'failed', 'refunded']),
  paymentMethod: paymentMethodSchema,
  tier: tierSchema,
  transactionHash: z.string().optional(),
  metadata: z.record(z.string(), z.unknown()).optional(),
});

// Presale statistics validation
export const presaleStatsSchema = z.object({
  totalRaised: z.number().min(0),
  target: z.number().min(0),
  participants: z.number().min(0).int(),
  timeRemaining: z.string(),
  progress: z.number().min(0).max(100),
});

// Vesting schedule validation
export const vestingScheduleSchema = z.object({
  totalTokens: z.number().min(0),
  vestedTokens: z.number().min(0),
  nextClaimDate: z.date().optional(),
  claimableAmount: z.number().min(0),
  totalPeriods: z.number().min(1).int(),
  currentPeriod: z.number().min(0).int(),
  vestingStart: z.date(),
  cliffPeriod: z.number().min(0), // in months
  vestingPeriod: z.number().min(1), // in months
});

// Claim tokens validation
export const claimTokensSchema = z.object({
  investmentId: z.string().uuid('Invalid investment ID'),
  amount: z.number().min(0.000001, 'Claim amount must be greater than 0'),
});

// Type exports
export type TokenPurchaseData = z.infer<typeof tokenPurchaseSchema>;
export type InvestmentData = z.infer<typeof investmentSchema>;
export type PresaleStatsData = z.infer<typeof presaleStatsSchema>;
export type VestingScheduleData = z.infer<typeof vestingScheduleSchema>;
export type ClaimTokensData = z.infer<typeof claimTokensSchema>;