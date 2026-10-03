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
   
