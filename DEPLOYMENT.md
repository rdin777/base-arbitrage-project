# 🚀 Deployment & Setup Guide

This guide covers local testing, testnet deployment, and running the arbitrage bot.

## ⚠️ Security Warning
**NEVER** commit your `.env` file or private keys to GitHub. The `.gitignore` is configured to prevent this, but always double-check before pushing.

---

## 🛠️ Part 1: Environment Setup

1. Navigate to the `bot` directory:
   ```bash
   cd bot
2.  Create a .env file
  cp .env.example .env
3. Fill in your details:
# Base Mainnet RPC (use Alchemy, QuickNode, or public RPC)
BASE_RPC_URL=https://mainnet.base.org

# Your wallet private key (DO NOT share!)
PRIVATE_KEY=0xyour_private_key_here

# Address of your deployed ArbitrageExecutor contract
CONTRACT_ADDRESS=0xYourDeployedContractAddressHere

# Minimum profit threshold to trigger execution (in ETH)
MIN_PROFIT=0.001

💻 Part 2: Local Testing (Recommended)
Test the contract against real Base Mainnet state without spending real money.
1. Start a local fork (in Terminal 1):
      anvil --fork-url https://mainnet.base.org
   Note: Anvil will provide 10 test accounts with 10,000 ETH each.
2.    Deploy the contract (in Terminal 2):
     cd ~/base-arbitrage-project
   forge script script/Deploy.s.sol \
     --rpc-url http://localhost:8545 \
     --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
     --broadcast
  Copy the deployed contract address and paste it into your bot/.env file.
 3.  Run the bot (in Terminal 3):
       cd bot
   npm run start
🌐 Part 3: Base Sepolia Testnet Deployment
When ready to test on a live network:
Get Testnet ETH: Use the Alchemy Base Sepolia Faucet.
Update .env: Change BASE_RPC_URL to your Base Sepolia RPC and PRIVATE_KEY to your testnet wallet key.
Update Deploy Script: Ensure script/Deploy.s.sol uses Base Sepolia router addresses.
Deploy:
   forge script script/Deploy.s.sol \
     --rpc-url $BASE_RPC_URL \
     --private-key $PRIVATE_KEY \
     --broadcast \
     --verify
 � Part 4: Contract Verification
If the --verify flag didn't work automatically, verify manually on Basescan:
forge verify-contract \
  --chain-id 84532 \
  --verifier basescan \
  --verifier-url https://api-sepolia.basescan.org/api \
  --etherscan-api-key YOUR_BASESCAN_API_KEY \
  YOUR_CONTRACT_ADDRESS \
  src/ArbitrageExecutor.sol:ArbitrageExecutor
(For Mainnet, use --chain-id 8453 and https://api.basescan.org/api)
🤖 Part 5: Running the Bot in Production
Ensure your .env is configured for Mainnet.
Ensure your contract is funded with a small amount of ETH for gas.
Start the bot:
   cd bot
   npm run start
4. Monitor the console for ✅ Arbitrage Opportunity Detected and transaction hashes.
5. 🔗 Useful Links
Base Documentation
Foundry Book
Uniswap V3 Docs
Aerodrome Docs
Basescan

