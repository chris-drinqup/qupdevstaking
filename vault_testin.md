# 🎯 QUP Staking Vault - Community Testing Guide

**Test our new staking vault and earn rewards while helping us improve the system!**

---

## 🚀 Quick Start (5 Minutes)

### Prerequisites
- A Solana wallet with devnet SOL
- Node.js installed on your computer
- 10 minutes to test

### 1. Get Test Tokens

**Request QUPDEV tokens from the team:**
- Join our Discord/Telegram
- Share your wallet address
- We'll send you 1000 QUPDEV test tokens

**Or if you have a devnet wallet:**
```bash
# Get devnet SOL
solana airdrop 2 --url devnet

# Set your cluster to devnet  
solana config set --url devnet
```

### 2. Download and Run the Tester

```bash
# Download the testing package
git clone [YOUR_REPO] qup-vault-test
cd qup-vault-test

# Install dependencies
npm install

# Check your wallet and balances
node vault_tester.js status

# Run the full test suite
node vault_tester.js test
```

**That's it!** The tester will automatically:
- ✅ Check your balances
- ✅ Stake some tokens
- ✅ Wait for rewards to accumulate  
- ✅ Claim rewards
- ✅ Test partial unstaking

---

## 📊 Understanding the System

### How QUP Staking Works

1. **Stake QUPDEV tokens** → Lock them in the vault
2. **Earn 1% daily rewards** → Automatically calculated
3. **Claim anytime** → Get your rewards
4. **Unstake anytime** → Get your principal back

### Key Features

- **No lockup period** - Unstake anytime
- **Compound rewards** - Stake your rewards to earn more
- **Real-time calculation** - Rewards calculated by the second
- **Secure smart contract** - Audited and tested code

### Reward Calculation

```
Daily Reward = Staked Amount × 1%
Hourly Reward = Daily Reward ÷ 24
Per-second Reward = Hourly Reward ÷ 3600
```

**Example:** 
- Stake 1000 QUPDEV
- After 24 hours → Earn 10 QUPDEV (1%)
- After 1 hour → Earn ~0.42 QUPDEV
- After 1 minute → Earn ~0.007 QUPDEV

---

## 🧪 Testing Scenarios

### Scenario 1: Basic Staking Test
```bash
# Check your status
node vault_tester.js status

# Stake 100 tokens
node vault_tester.js stake 100

# Wait 5 minutes, then check rewards
node vault_tester.js status

# Claim your rewards
node vault_tester.js claim
```

### Scenario 2: Multiple Stakes
```bash
# First stake
node vault_tester.js stake 50

# Wait 2 minutes
# Second stake (should accumulate previous rewards)
node vault_tester.js stake 25

# Check total stake and rewards
node vault_tester.js status
```

### Scenario 3: Partial Unstaking
```bash
# Stake some tokens
node vault_tester.js stake 200

# Wait for rewards to accumulate
# Unstake half
node vault_tester.js unstake 100

# Check remaining stake and rewards
node vault_tester.js status
```

### Scenario 4: Full Test Suite
```bash
# Runs all tests automatically
node vault_tester.js test
```

---

## 🔧 Advanced Testing

### Custom Wallet Path
```bash
# Use a specific wallet file
ANCHOR_WALLET=/path/to/your/wallet.json node vault_tester.js status
```

### Manual Testing Commands
```bash
# Check everything
node vault_tester.js status

# Stake specific amount
node vault_tester.js stake 250

# Unstake specific amount  
node vault_tester.js unstake 50

# Claim all rewards
node vault_tester.js claim

# Run automated test
node vault_tester.js test
```

### Understanding the Output

**Balance Check:**
```
📊 BALANCE CHECK
==================
SOL Balance: 1.5 SOL
QUPDEV Balance: 1000 QUPDEV
```

**Vault Status:**
```
🏛️  VAULT STATUS  
==================
✅ Vault found and active
   Total Staked: 5000 tokens
   Reward Rate: 100 basis points per day (1%)
   Vault Token Balance: 5250 QUPDEV
```

**Your Stake:**
```
👤 USER STAKE STATUS
=====================
✅ User stake found
   Staked Amount: 100 QUPDEV
   Pending Rewards: 2 QUPDEV
   Time Since Last Stake: 2h 15m
   Total Claimable: 3 QUPDEV
```

---

## 🐛 What to Test & Report

### Core Functionality
- [ ] **Staking works** - Can you stake tokens successfully?
- [ ] **Rewards accumulate** - Do you see rewards growing over time?
- [ ] **Claims work** - Can you claim your rewards?
- [ ] **Unstaking works** - Can you get your tokens back?

### Edge Cases
- [ ] **Very small stakes** - Try staking 1 token
- [ ] **Multiple stakes** - Stake several times in a row
- [ ] **Quick claim/unstake** - Try claiming/unstaking immediately
- [ ] **Full unstake** - Try unstaking everything

### User Experience
- [ ] **Clear error messages** - Are errors easy to understand?
- [ ] **Transaction speed** - How fast do transactions confirm?
- [ ] **Accurate calculations** - Do reward amounts make sense?

### What to Report

**Found a bug?** Please report:
1. What you were trying to do
2. What command you ran
3. The full error message
4. Your wallet address (for investigation)

**Suggestions welcome:**
- UI/UX improvements
- Additional features
- Better error messages
- Documentation improvements

---

## 💡 Pro Tips

### Maximize Your Testing

1. **Test with small amounts first** - Start with 10-50 tokens
2. **Wait between actions** - Let rewards accumulate to see calculations
3. **Try edge cases** - What happens with 1 token? With your full balance?
4. **Test multiple sessions** - Exit and restart the tester
5. **Check transaction history** - View your txs on Solana Explorer

### Common Issues & Solutions

**"No QUPDEV tokens found"**
→ Request test tokens from the team or check your wallet address

**"Cannot find module"**  
→ Run `npm install` in the project directory

**"expected environment variable ANCHOR_WALLET"**
→ Set your wallet: `export ANCHOR_WALLET=~/.config/solana/id.json`

**"Transaction failed"**
→ Check you have enough SOL for transaction fees

**"Insufficient stake amount"**
→ You're trying to unstake more than you have staked

### Performance Benchmarks

Help us establish benchmarks by reporting:
- **Transaction confirmation times**
- **Gas costs for each operation**
- **Reward calculation accuracy**
- **System performance under load**

---

## 🏆 Reward for Testing

**Active testers get rewards!**

- **Test all scenarios** → 50 QUP tokens (mainnet)
- **Find critical bugs** → 200 QUP tokens  
- **Suggest improvements** → 25 QUP tokens
- **Help other testers** → 25 QUP tokens

**How to claim:**
1. Complete testing checklist
2. Submit your wallet address
3. Share feedback in our Discord
4. Rewards distributed after mainnet launch

---

## 📱 Getting Help

### Community Support
- **Discord:** [Your Discord Link]
- **Telegram:** [Your Telegram Link] 
- **GitHub Issues:** [Your GitHub Link]

### Technical Support
- **DM the dev team** for urgent issues
- **Post in #testing channel** for general questions
- **Create GitHub issue** for bugs

### Share Your Results
Post screenshots of successful tests with:
- Your wallet address (last 4 chars)
- Test scenario completed
- Any issues encountered
- Suggestions for improvement

---

## 🎉 Next Steps

**After Testing:**
1. Share feedback with the team
2. Join our mainnet launch announcement
3. Get ready for real QUP staking rewards
4. Help onboard other community members

**Mainnet Launch:**
- Higher reward rates
- Additional staking pools
- Governance features
- NFT rewards for early adopters

---

**Thank you for helping test the QUP Staking Vault!**

*Your feedback is crucial for a successful mainnet launch. Happy testing! 🚀*

---

## 📋 Testing Checklist

Copy this checklist and share your results:

```
QUP Vault Testing Checklist - [Your Name/Handle]
==============================================

Environment Setup:
[ ] Devnet SOL acquired
[ ] QUPDEV test tokens received
[ ] Tester script running
[ ] Initial balance check passed

Basic Functionality:
[ ] Stake 50 tokens - Success ✅ / Failed ❌
[ ] Wait 5 minutes and check rewards ✅ / ❌
[ ] Claim rewards ✅ / ❌  
[ ] Unstake partial amount ✅ / ❌
[ ] Check final balances ✅ / ❌

Advanced Testing:
[ ] Multiple stake operations ✅ / ❌
[ ] Very small stake (1 token) ✅ / ❌
[ ] Full unstake ✅ / ❌
[ ] Quick claim/unstake sequence ✅ / ❌

Performance:
- Average transaction time: ___ seconds
- Total gas costs: ___ SOL
- Reward calculation accuracy: ✅ / ❌

Issues Found:
- Issue 1: [Description]
- Issue 2: [Description]

Suggestions:
- Suggestion 1: [Description]
- Suggestion 2: [Description]

Overall Rating: ⭐⭐⭐⭐⭐ (1-5 stars)
Would recommend to others: Yes / No

Wallet (last 4 chars): ____
Completed on: [Date]
```
