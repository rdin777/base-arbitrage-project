import { ArbitrageBot } from './ArbitrageBot';
import { parseEther } from 'viem';

// Configuration
const CONFIG = {
  RPC_URL: process.env.BASE_RPC_URL || 'https://mainnet.base.org',
  PRIVATE_KEY: process.env.PRIVATE_KEY || '',
  CONTRACT_ADDRESS: process.env.CONTRACT_ADDRESS || '',
  MIN_PROFIT: '0.001' // 0.001 ETH
};

// Usage example
async function main() {
  console.log('🤖 Starting Arbitrage Bot...\n');

  const bot = new ArbitrageBot(
    CONFIG.RPC_URL,
    CONFIG.PRIVATE_KEY,
    CONFIG.CONTRACT_ADDRESS,
    CONFIG.MIN_PROFIT
  );

  // Example of an arbitrage opportunity (in reality, this data comes from a detector)
  const mockOpportunity = {
    tokenIn: '0x4200000000000000000000000000000000000006', // WETH on Base
    tokenOut: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913', // USDC on Base
    fee1: 3000, // 0.3% on Uniswap
    fee2: 3000, // 0.3% on Aerodrome
    spreadPercent: 0.57, // 0.57% spread
    estimatedProfit: parseEther('0.005'), // 0.005 ETH profits
    amountIn: parseEther('1.0') // 1 ETH for the swap
  };

  console.log('Monitoring for arbitrage opportunities...\n');

  // In a real bot, there would be a loop here with a WebSocket subscription.
  // As an example, let's simply handle the mock capability.
  await bot.processOpportunity(mockOpportunity);

  console.log('\nBot stopped.');
}

main().catch(console.error);

