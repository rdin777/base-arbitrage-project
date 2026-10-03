# 🚀 Base Arbitrage Project

Real-time DEX arbitrage detector + atomic execution smart contract on Base L2.

## 📦 Components

### 1. Atomic Arbitrage Smart Contract (`src/`)
Solidity smart contract that executes atomic arbitrage using EIP-3156 flash loans. No upfront capital required — borrow, swap, repay, and keep the profit in a single, atomic transaction.

**Features:**
- Flash loan integration (ERC3156)
- Atomic execution (all-or-nothing, zero risk of partial failure)
- Built and tested with Foundry
- Security-focused design (Checks-Effects-Interactions pattern)
- 6/6 unit tests passing

### 2. Arbitrage Detector Bot (`bot/`)
Lightweight TypeScript bot that monitors Uniswap V3 and Aerodrome pools on Base, calculates real net profit (fees + gas + slippage), and automatically triggers the smart contract when a profitable opportunity is found.

**Features:**
- Real-time WebSocket monitoring
- Net profit calculation
- Runs efficiently on minimal resources (1GB RAM)
- Built with modern `viem` stack

## 🛠️ Tech Stack

- **Smart Contract:** Solidity ^0.8.20, Foundry, OpenZeppelin v5
- **Bot:** TypeScript, Viem, Node.js
- **Network:** Base L2 (Mainnet & Sepolia Testnet)

## 🚀 Quick Start

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Node.js 18+ and npm

### 1. Smart Contract
```bash
# Install dependencies
forge install

# Compile
forge build

# Run tests
forge test

# Run local fork (requires internet)
anvil --fork-url https://mainnet.base.org
