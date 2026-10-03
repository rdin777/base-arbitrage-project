import { createPublicClient, createWalletClient, http, parseEther, formatEther } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { base } from 'viem/chains';

// ABI of the contract ArbitrageExecutor
const ARBITRAGE_EXECUTOR_ABI = [
  {
    inputs: [
      { internalType: 'address', name: 'tokenBorrow', type: 'address' },
      { internalType: 'uint256', name: 'amount', type: 'uint256' },
      { internalType: 'address', name: 'tokenIn', type: 'address' },
      { internalType: 'address', name: 'tokenOut', type: 'address' },
      { internalType: 'uint24', name: 'fee1', type: 'uint24' },
      { internalType: 'uint24', name: 'fee2', type: 'uint24' }
    ],
    name: 'executeArbitrage',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function'
  },
  {
    inputs: [{ internalType: 'address', name: 'token', type: 'address' }],
    name: 'getTokenBalance',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function'
  }
] as const;

interface ArbitrageOpportunity {
  tokenIn: string;
  tokenOut: string;
  fee1: number;
  fee2: number;
  spreadPercent: number;
  estimatedProfit: bigint;
  amountIn: bigint;
}

export class ArbitrageBot {
  private publicClient: any;
  private walletClient: any;
  private contractAddress: string;
  private minProfitThreshold: bigint;

  constructor(
    rpcUrl: string,
    privateKey: string,
    contractAddress: string,
    minProfitThreshold: string = '0.001' // 0.001 ETH by default
  ) {
    this.contractAddress = contractAddress;
    this.minProfitThreshold = parseEther(minProfitThreshold);

    // Public client (read-only)
    this.publicClient = createPublicClient({
      chain: base,
      transport: http(rpcUrl)
    });

    // Client wallet (for sending transactions)
    const account = privateKeyToAccount(privateKey as `0x${string}`);
    this.walletClient = createWalletClient({
      chain: base,
      transport: http(rpcUrl),
      account
    });

    console.log('✅ ArbitrageBot initialized');
    console.log(`Contract: ${contractAddress}`);
    console.log(`Min profit threshold: ${minProfitThreshold} ETH`);
  }

  // Checking whether the deal is profitable
  async checkOpportunity(opportunity: ArbitrageOpportunity): Promise<boolean> {
    const { estimatedProfit, spreadPercent } = opportunity;

    console.log(`\n🔍 Arbitrage Opportunity Detected:`);
    console.log(`Token Pair: ${opportunity.tokenIn} → ${opportunity.tokenOut}`);
    console.log(`Spread: ${spreadPercent.toFixed(4)}%`);
    console.log(`Estimated Profit: ${formatEther(estimatedProfit)} ETH`);

    // We check whether the profit exceeds the threshold.
    if (estimatedProfit >= this.minProfitThreshold) {
      console.log('✅ Profit threshold met! Executing...');
      return true;
    } else {
      console.log('❌ Profit below threshold. Skipping.');
      return false;
    }
  }

  // Enforcement of an arbitration award
  async executeArbitrage(opportunity: ArbitrageOpportunity): Promise<string | null> {
    try {
      console.log('\n🚀 Executing arbitrage...');

      // We call executeArbitrage on the contract.
      const hash = await this.walletClient.writeContract({
        address: this.contractAddress,
        abi: ARBITRAGE_EXECUTOR_ABI,
        functionName: 'executeArbitrage',
        args: [
          opportunity.tokenIn as `0x${string}`, // tokenBorrow
          opportunity.amountIn,
          opportunity.tokenIn as `0x${string}`,
          opportunity.tokenOut as `0x${string}`,
          opportunity.fee1,
          opportunity.fee2
        ]
      });

      console.log(`✅ Transaction sent: https://basescan.org/tx/${hash}`);
      
      // We are awaiting confirmation.
      const receipt = await this.publicClient.waitForTransactionReceipt({ hash });
      
      if (receipt.status === 'success') {
        console.log('✅ Arbitrage executed successfully!');
        return hash;
      } else {
        console.log('❌ Transaction failed');
        return null;
      }
    } catch (error) {
      console.error('❌ Error executing arbitrage:', error);
      return null;
    }
  }

  // Primary function: verification and execution
  async processOpportunity(opportunity: ArbitrageOpportunity): Promise<void> {
    const shouldExecute = await this.checkOpportunity(opportunity);
    
    if (shouldExecute) {
      await this.executeArbitrage(opportunity);
    }
  }
}

