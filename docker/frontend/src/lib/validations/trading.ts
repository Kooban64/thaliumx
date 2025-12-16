import { z } from 'zod';

// Trading pair symbol validation
export const tradingPairSchema = z
  .string()
  .regex(/^[A-Z]{2,10}\/[A-Z]{2,10}$/, 'Invalid trading pair format (e.g., BTC/USDT)');

// Amount validation for crypto trading
export const cryptoAmountSchema = z
  .string()
  .min(1, 'Amount is required')
  .refine(
    (val) => {
      const num = parseFloat(val);
      return !isNaN(num) && num > 0 && num <= 1000000; // Max 1M units
    },
    'Amount must be a positive number and not exceed 1,000,000'
  )
  .refine(
    (val) => {
      const parts = val.split('.');
      return parts.length <= 2 && (!parts[1] || parts[1].length <= 8); // Max 8 decimal places
    },
    'Amount cannot have more than 8 decimal places'
  );

// Price validation for limit orders
export const priceSchema = z
  .string()
  .min(1, 'Price is required')
  .refine(
    (val) => {
      const num = parseFloat(val);
      return !isNaN(num) && num > 0 && num <= 10000000; // Max $10M
    },
    'Price must be a positive number and not exceed $10,000,000'
  )
  .refine(
    (val) => {
      const parts = val.split('.');
      return parts.length <= 2 && (!parts[1] || parts[1].length <= 8); // Max 8 decimal places
    },
    'Price cannot have more than 8 decimal places'
  );

// Slippage tolerance validation
export const slippageSchema = z
  .number()
  .min(0.1, 'Slippage must be at least 0.1%')
  .max(50, 'Slippage cannot exceed 50%')
  .optional();

// Slippage protection validation
export const slippageProtectionSchema = z.object({
  maxSlippagePercent: z
    .number()
    .min(0.1, 'Max slippage must be at least 0.1%')
    .max(20, 'Max slippage cannot exceed 20% for safety')
    .default(5),
  priceImpactThreshold: z
    .number()
    .min(0.01, 'Price impact threshold must be at least 0.01%')
    .max(10, 'Price impact threshold cannot exceed 10%')
    .default(2),
  enableSlippageProtection: z.boolean().default(true),
});

// Market impact validation
export const marketImpactSchema = z.object({
  estimatedPriceImpact: z
    .number()
    .min(0, 'Price impact cannot be negative')
    .max(100, 'Price impact cannot exceed 100%'),
  orderSizeVsLiquidity: z
    .number()
    .min(0, 'Order size ratio cannot be negative')
    .max(1, 'Order size cannot exceed available liquidity'),
});

// Advanced order validation with slippage protection
export const advancedMarketOrderSchema = z.object({
  symbol: tradingPairSchema,
  side: z.enum(['buy', 'sell']),
  amount: cryptoAmountSchema,
  slippageProtection: slippageProtectionSchema.optional(),
  marketImpact: marketImpactSchema.optional(),
}).refine((data) => {
  // Additional validation: ensure amount doesn't cause excessive market impact
  if (data.marketImpact && data.marketImpact.estimatedPriceImpact > 10) {
    return false;
  }
  return true;
}, {
  message: 'Order would cause excessive market impact (>10%). Reduce order size.',
});

// Advanced limit order with price validation
export const advancedLimitOrderSchema = z.object({
  symbol: tradingPairSchema,
  side: z.enum(['buy', 'sell']),
  amount: cryptoAmountSchema,
  price: priceSchema,
  timeInForce: z.enum(['GTC', 'IOC', 'FOK']).default('GTC'),
  postOnly: z.boolean().default(false),
}).refine((data) => {
  // Validate that limit price is reasonable compared to market
  // This would typically be checked against current market price
  const price = parseFloat(data.price);
  // For now, just ensure price is within reasonable bounds
  return price > 0.000001 && price < 10000000;
}, {
  message: 'Limit price is outside reasonable trading range.',
});

// Market order validation schema
export const marketOrderSchema = z.object({
  symbol: tradingPairSchema,
  side: z.enum(['buy', 'sell']),
  amount: cryptoAmountSchema,
  slippage: slippageSchema,
});

// Limit order validation schema
export const limitOrderSchema = z.object({
  symbol: tradingPairSchema,
  side: z.enum(['buy', 'sell']),
  amount: cryptoAmountSchema,
  price: priceSchema,
});

// Stop loss order validation schema
export const stopLossOrderSchema = z.object({
  symbol: tradingPairSchema,
  side: z.enum(['buy', 'sell']),
  amount: cryptoAmountSchema,
  stopPrice: priceSchema,
});

// Stop limit order validation schema
export const stopLimitOrderSchema = z.object({
  symbol: tradingPairSchema,
  side: z.enum(['buy', 'sell']),
  amount: cryptoAmountSchema,
  stopPrice: priceSchema,
  limitPrice: priceSchema,
});

// Take profit order validation schema
export const takeProfitOrderSchema = z.object({
  symbol: tradingPairSchema,
  side: z.enum(['buy', 'sell']),
  amount: cryptoAmountSchema,
  takeProfitPrice: priceSchema,
});

// Trailing stop order validation schema
export const trailingStopOrderSchema = z.object({
  symbol: tradingPairSchema,
  side: z.enum(['buy', 'sell']),
  amount: cryptoAmountSchema,
  trailingPercent: z
    .number()
    .min(0.1, 'Trailing percentage must be at least 0.1%')
    .max(20, 'Trailing percentage cannot exceed 20%'),
});

// Wallet address validation
export const walletAddressSchema = z
  .string()
  .min(20, 'Wallet address is too short')
  .max(100, 'Wallet address is too long')
  .regex(/^0x[a-fA-F0-9]{40}$/, 'Invalid Ethereum wallet address format');

// Broker code validation
export const brokerCodeSchema = z
  .string()
  .max(50, 'Broker code is too long')
  .regex(/^[A-Z0-9_-]*$/, 'Broker code contains invalid characters')
  .optional();

// Order cancellation validation
export const cancelOrderSchema = z.object({
  orderId: z.string().uuid('Invalid order ID format'),
});

// Wallet balance check validation
export const balanceCheckSchema = z.object({
  currency: z.string().length(3, 'Currency must be 3 characters').toUpperCase(),
  amount: cryptoAmountSchema,
});

// Slippage calculation utilities
export function calculateSlippageTolerance(
  currentPrice: number,
  orderPrice: number,
  side: 'buy' | 'sell'
): number {
  if (currentPrice <= 0 || orderPrice <= 0) return 0;

  const difference = Math.abs(currentPrice - orderPrice);
  const averagePrice = (currentPrice + orderPrice) / 2;

  return (difference / averagePrice) * 100;
}

export function validateSlippageProtection(
  currentPrice: number,
  orderPrice: number,
  maxSlippagePercent: number,
  side: 'buy' | 'sell'
): { isValid: boolean; actualSlippage: number; message?: string } {
  const actualSlippage = calculateSlippageTolerance(currentPrice, orderPrice, side);

  if (actualSlippage > maxSlippagePercent) {
    return {
      isValid: false,
      actualSlippage,
      message: `Slippage ${actualSlippage.toFixed(2)}% exceeds maximum allowed ${maxSlippagePercent}%`
    };
  }

  return {
    isValid: true,
    actualSlippage
  };
}

export function estimatePriceImpact(
  orderSize: number,
  availableLiquidity: number,
  marketDepth: number = 0.1
): number {
  if (availableLiquidity <= 0) return 100; // Infinite impact

  const impactRatio = orderSize / availableLiquidity;

  // Simplified price impact model
  // In reality, this would use more sophisticated market depth calculations
  return Math.min(impactRatio * marketDepth * 100, 100);
}

// Type exports
export type MarketOrderData = z.infer<typeof marketOrderSchema>;
export type LimitOrderData = z.infer<typeof limitOrderSchema>;
export type StopLossOrderData = z.infer<typeof stopLossOrderSchema>;
export type StopLimitOrderData = z.infer<typeof stopLimitOrderSchema>;
export type TakeProfitOrderData = z.infer<typeof takeProfitOrderSchema>;
export type TrailingStopOrderData = z.infer<typeof trailingStopOrderSchema>;
export type CancelOrderData = z.infer<typeof cancelOrderSchema>;
export type BalanceCheckData = z.infer<typeof balanceCheckSchema>;
export type AdvancedMarketOrderData = z.infer<typeof advancedMarketOrderSchema>;
export type AdvancedLimitOrderData = z.infer<typeof advancedLimitOrderSchema>;
export type SlippageProtectionData = z.infer<typeof slippageProtectionSchema>;
export type MarketImpactData = z.infer<typeof marketImpactSchema>;