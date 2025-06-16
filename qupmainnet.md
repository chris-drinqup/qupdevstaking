# QUP Production Deployment Guide - Mainnet Launch

*Complete step-by-step guide for deploying QUP staking vault to Solana Mainnet*

**Date:** May 30, 2025  
**Status:** Ready for production deployment after devnet testing validation  
**Prerequisites:** Successful devnet testing completed

---

## 🎯 PRODUCTION TOKEN INFORMATION

**Production QUP Token:**
- **Mint Address:** `2xaPstY4XqJ2gUA1mpph3XmvmPZGuTuJ658AeqX3gJ6F`
- **LP Address:** `9DkA6QwGGGziuyKbKP9MYChG3sEN2Unrmdyq4fTwAaTR`
- **Network:** Solana Mainnet
- **Symbol:** QUP
- **Name:** QUP Token

---

## 📋 PRE-DEPLOYMENT CHECKLIST

### ✅ Devnet Validation Requirements
- [ ] Devnet staking vault tested and working
- [ ] Community testing completed successfully
- [ ] All major bugs identified and fixed
- [ ] Economic model validated (reward rates, etc.)
- [ ] Security review completed
- [ ] Frontend properly recognizes QUPDEV tokens on devnet

### ✅ Mainnet Preparation Requirements
- [ ] Sufficient SOL for deployment (~5-10 SOL recommended)
- [ ] Production wallet secured with hardware wallet/multi-sig
- [ ] Token metadata prepared and hosted
- [ ] Production domain ready (drinqup.com)
- [ ] Community announcement prepared
- [ ] Emergency procedures documented

---

## 🔧 STEP 1: UPDATE TOKEN REGISTRY FOR PRODUCTION

### A. Update Frontend Token Registry

Replace the devnet token registry with production values:

```javascript
// PRODUCTION TOKEN REGISTRY
const TOKEN_REGISTRY = {
    // Production QUP token on mainnet
    "2xaPstY4XqJ2gUA1mpph3XmvmPZGuTuJ658AeqX3gJ6F": {
        symbol: "QUP",
        name: "QUP Token",
        decimals: 9, // Verify this with your token
        logoURI: "https://drinqup.com/qup-logo.png",
        network: "mainnet",
        description: "Official QUP staking and rewards token",
        website: "https://drinqup.com",
        metadataUri: "https://drinqup.com/token_metadata.json"
    },
    // Keep devnet for testing (optional)
    "8bjKA2mkXMdkUHC6m8TfyQcksTDLKeP61XmFFcVViYef": {
        symbol: "QUPDEV",
        name: "QUP Development Token", 
        decimals: 9,
        logoURI: "https://drinqup.com/qupdev-logo.png",
        network: "devnet"
    }
};
```

### B. Update Vault Configuration

```javascript
// PRODUCTION VAULT CONFIG
const VAULT_CONFIG = {
    // Will be generated during deployment
    programId: new solanaWeb3.PublicKey('YOUR_MAINNET_PROGRAM_ID'),
    vaultPda: new solanaWeb3.PublicKey('YOUR_MAINNET_VAULT_PDA'),
    tokenVaultPda: new solanaWeb3.PublicKey('YOUR_MAINNET_TOKEN_VAULT_PDA'),
    qupMint: new solanaWeb3.PublicKey('2xaPstY4XqJ2gUA1mpph3XmvmPZGuTuJ658AeqX3gJ6F'),
    network: 'mainnet-beta' // Changed from 'devnet'
};
```

### C. Update Connection URL

```javascript
// PRODUCTION CONNECTION
connection = new solanaWeb3.Connection('https://api.mainnet-beta.solana.com', 'confirmed');

// Alternative RPC providers for better reliability:
// connection = new solanaWeb3.Connection('https://solana-api.projectserum.com', 'confirmed');
// connection = new solanaWeb3.Connection('https://rpc.ankr.com/solana', 'confirmed');
```

---

## 🏗️ STEP 2: DEPLOY PROGRAM TO MAINNET

### A. Environment Setup for Mainnet

```bash
# Switch to mainnet
solana config set --url mainnet-beta

# Verify you're on mainnet
solana config get
# Should show: RPC URL: https://api.mainnet-beta.solana.com

# Check your wallet balance (you need ~5-10 SOL for deployment)
solana balance

# If you need more SOL, buy from exchanges and transfer to your wallet
```

### B. Build Production Program

```bash
# Navigate to your staking program directory
cd ~/krakenbot/pro/questakingpool/new_qup_staking

# Clean previous builds
cargo clean

# Build for production (with optimizations)
anchor build --release

# Verify the program binary
ls -la target/deploy/
# Should show qup_staking_vault.so (~300KB+)
```

### C. Deploy to Mainnet

```bash
# Deploy the program (THIS COSTS SOL!)
solana program deploy target/deploy/qup_staking_vault.so

# SAVE THIS PROGRAM ID - You'll need it!
# Example output: Program Id: AbCdEf123456789...
export MAINNET_PROGRAM_ID="YOUR_ACTUAL_PROGRAM_ID_HERE"

echo "🎯 Mainnet Program ID: $MAINNET_PROGRAM_ID"
```

### D. Update Program ID in Code

```bash
# Update the declare_id! macro in your Rust code
sed -i "s/declare_id!(\".*\")/declare_id!(\"$MAINNET_PROGRAM_ID\")/" programs/qup_staking_vault/src/lib.rs

# Rebuild with correct Program ID
anchor build --release

# Redeploy with the correct program ID
solana program deploy target/deploy/qup_staking_vault.so --program-id target/deploy/qup_staking_vault-keypair.json
```

---

## 🔑 STEP 3: GENERATE MAINNET VAULT ADDRESSES

### A. Calculate Production PDAs

```bash
# Create mainnet address calculator
cat > mainnet_vault_init.js << 'EOF'
const { Connection, PublicKey, Keypair, clusterApiUrl } = require('@solana/web3.js');
const fs = require('fs');

async function calculateMainnetAddresses() {
    try {
        console.log('🚀 Calculating mainnet vault addresses...');

        // Connect to mainnet
        const connection = new Connection('https://api.mainnet-beta.solana.com', 'confirmed');
        console.log('✅ Connected to mainnet');

        // Load your production wallet
        const walletPath = process.env.ANCHOR_WALLET || '~/.config/solana/id.json';
        const expandedPath = walletPath.replace('~', require('os').homedir());
        const walletKeypair = Keypair.fromSecretKey(
            new Uint8Array(JSON.parse(fs.readFileSync(expandedPath, 'utf8')))
        );
        console.log('✅ Production wallet loaded:', walletKeypair.publicKey.toString());

        // Program and token addresses
        const programId = new PublicKey(process.env.MAINNET_PROGRAM_ID);
        const qupMint = new PublicKey('2xaPstY4XqJ2gUA1mpph3XmvmPZGuTuJ658AeqX3gJ6F');

        // Find vault PDA
        const [vaultPda, vaultBump] = PublicKey.findProgramAddressSync(
            [Buffer.from('vault'), walletKeypair.publicKey.toBuffer()],
            programId
        );
        console.log('✅ Vault PDA:', vaultPda.toString());

        // Find token vault PDA
        const [tokenVaultPda, tokenVaultBump] = PublicKey.findProgramAddressSync(
            [Buffer.from('token_vault'), walletKeypair.publicKey.toBuffer()],
            programId
        );
        console.log('✅ Token Vault PDA:', tokenVaultPda.toString());

        // Save addresses for production
        const addresses = {
            network: 'mainnet-beta',
            programId: programId.toString(),
            authority: walletKeypair.publicKey.toString(),
            qupMint: qupMint.toString(),
            vaultPda: vaultPda.toString(),
            tokenVaultPda: tokenVaultPda.toString(),
            vaultBump: vaultBump,
            tokenVaultBump: tokenVaultBump,
            timestamp: new Date().toISOString(),
            status: 'ready_for_init'
        };

        fs.writeFileSync('./mainnet_vault_addresses.json', JSON.stringify(addresses, null, 2));
        console.log('\n✅ Mainnet addresses saved to mainnet_vault_addresses.json');

        return addresses;

    } catch (error) {
        console.error('❌ Error:', error);
        throw error;
    }
}

if (require.main === module) {
    if (!process.env.MAINNET_PROGRAM_ID) {
        console.error('❌ Please set MAINNET_PROGRAM_ID environment variable');
        process.exit(1);
    }
    
    calculateMainnetAddresses()
        .then((result) => {
            console.log('\n🎉 Mainnet vault addresses calculated successfully!');
            console.log('Next step: Initialize the vault with these addresses');
        })
        .catch((error) => {
            console.error('Failed:', error);
            process.exit(1);
        });
}
EOF

# Set your program ID and run
export MAINNET_PROGRAM_ID="YOUR_ACTUAL_PROGRAM_ID"
node mainnet_vault_init.js
```

---

## 🌐 STEP 4: SETUP PRODUCTION METADATA

### A. Host Token Metadata

Create and host the official token metadata at `https://drinqup.com/token_metadata.json`:

```json
{
  "name": "QUP Token",
  "symbol": "QUP",
  "description": "Official QUP staking and rewards token for the DrinQUP ecosystem",
  "image": "https://drinqup.com/qup-logo.png",
  "external_url": "https://drinqup.com",
  "properties": {
    "files": [
      {
        "uri": "https://drinqup.com/qup-logo.png",
        "type": "image/png"
      }
    ],
    "category": "fungible",
    "creators": [
      {
        "address": "YOUR_AUTHORITY_ADDRESS",
        "share": 100
      }
    ]
  },
  "attributes": [
    {
      "trait_type": "Type",
      "value": "Utility Token"
    },
    {
      "trait_type": "Network",
      "value": "Solana"
    },
    {
      "trait_type": "Use Case",
      "value": "Staking & Rewards"
    }
  ]
}
```

### B. Prepare Production Assets

```bash
# Create production assets directory
mkdir -p production_assets

# Copy/create these files:
# - qup-logo.png (high quality token logo)
# - qup-icon.ico (website favicon)
# - social-preview.png (for social media)

# Upload to https://drinqup.com/
# Ensure these URLs work:
# https://drinqup.com/qup-logo.png
# https://drinqup.com/token_metadata.json
```

---

## 🖥️ STEP 5: DEPLOY PRODUCTION FRONTEND

### A. Create Production Website

```bash
# Create production branch/repository
git checkout -b production

# Update frontend with production values
# Replace all occurrences of:
# - Devnet URLs → Mainnet URLs
# - QUPDEV → QUP
# - Devnet program/vault addresses → Mainnet addresses
# - Test messaging → Production messaging
```

### B. Update Website Content

```html
<!-- Update title and descriptions -->
<title>QUP Staking Vault - Earn Rewards</title>

<!-- Update badges -->
<div class="status-badge">✅ LIVE ON MAINNET</div>

<!-- Update warnings -->
<p>Official QUP Staking Platform - Real tokens and rewards!</p>

<!-- Add security warnings -->
<div class="security-notice">
    ⚠️ This is the live mainnet application using real QUP tokens.
    Double-check you're on the official domain: drinqup.com
</div>
```

### C. Deploy Production Site

```bash
# Option 1: GitHub Pages (if using custom domain)
# Set up custom domain in repository settings
# Point drinqup.com to GitHub Pages

# Option 2: Dedicated hosting
# Deploy to Vercel, Netlify, or your own server
# Ensure HTTPS and proper security headers

# Verify deployment
curl -I https://drinqup.com
# Should return 200 OK with HTTPS
```

---

## 🔐 STEP 6: INITIALIZE PRODUCTION VAULT

### A. Pre-initialization Checklist

```bash
# Verify you have enough SOL for initialization
solana balance
# Need ~0.5-1 SOL for vault initialization

# Verify you're on mainnet
solana config get

# Check token details
spl-token display 2xaPstY4XqJ2gUA1mpph3XmvmPZGuTuJ658AeqX3gJ6F

# Verify vault addresses
cat mainnet_vault_addresses.json
```

### B. Initialize Mainnet Vault

```bash
# Create initialization script for mainnet
cat > initialize_mainnet_vault.js << 'EOF'
// Mainnet vault initialization script
// This initializes the production QUP staking vault

const { Connection, PublicKey, Keypair, Transaction, SystemProgram } = require('@solana/web3.js');
const { TOKEN_PROGRAM_ID, RENT_PROGRAM_ID } = require('@solana/spl-token');
const fs = require('fs');

async function initializeMainnetVault() {
    try {
        console.log('🚀 Initializing MAINNET QUP Staking Vault...');
        console.log('⚠️  This is PRODUCTION - using real QUP tokens!');

        // Load configuration
        const config = JSON.parse(fs.readFileSync('./mainnet_vault_addresses.json', 'utf8'));
        
        // Connect to mainnet
        const connection = new Connection('https://api.mainnet-beta.solana.com', 'confirmed');
        
        // Load wallet
        const walletKeypair = Keypair.fromSecretKey(
            new Uint8Array(JSON.parse(fs.readFileSync(process.env.ANCHOR_WALLET || '~/.config/solana/id.json', 'utf8')))
        );

        console.log('Authority:', walletKeypair.publicKey.toString());
        console.log('Program ID:', config.programId);
        console.log('QUP Mint:', config.qupMint);
        console.log('Vault PDA:', config.vaultPda);

        // TODO: Build and send initialize_vault instruction
        // This requires the full Anchor integration
        
        console.log('✅ Mainnet vault initialization would happen here');
        console.log('💡 Complete the Anchor integration for actual initialization');

    } catch (error) {
        console.error('❌ Initialization failed:', error);
        throw error;
    }
}

// Safety check
if (require.main === module) {
    console.log('⚠️  MAINNET DEPLOYMENT - Are you sure? (Ctrl+C to cancel)');
    setTimeout(() => {
        initializeMainnetVault().catch(console.error);
    }, 5000);
}
EOF

# Run with caution (this is mainnet!)
node initialize_mainnet_vault.js
```

---

## 🧪 STEP 7: PRODUCTION TESTING & VALIDATION

### A. Comprehensive Testing Checklist

```bash
# Test with small amounts first
# Test all functionality:
# - Wallet connection (mainnet)
# - QUP token detection
# - Staking small amounts (1-10 QUP)
# - Reward calculation
# - Unstaking
# - Reward claiming

# Test on multiple devices/browsers
# Test with different wallet types
# Load testing with multiple users
```

### B. Security Verification

```bash
# Verify contract addresses match deployed code
# Audit all transaction signatures
# Test emergency procedures
# Verify no admin backdoors
# Check reward rate calculations
# Validate token security
```

---

## 📊 STEP 8: MONITORING & OPERATIONS

### A. Setup Monitoring

```bash
# Monitor vault health
# Track total staked amount
# Monitor reward distribution
# Alert on unusual activity
# Track user adoption metrics
```

### B. Emergency Procedures

```markdown
### Emergency Contacts
- Technical Lead: [Your contact]
- Security Team: [Security contact]
- Community Manager: [Community contact]

### Emergency Procedures
1. **Contract Issue**: Pause functionality if possible
2. **Frontend Issue**: Display maintenance notice
3. **Security Incident**: Immediate investigation and communication
4. **High Volume**: Scale RPC endpoints

### Emergency Wallet Access
- Multi-sig wallet for critical operations
- Hardware wallet backup
- Secure key recovery procedures
```

---

## 🚀 STEP 9: LAUNCH SEQUENCE

### A. Soft Launch (Limited Users)

```markdown
1. Deploy to production
2. Test with internal team
3. Invite 10-20 beta users
4. Monitor for 24-48 hours
5. Fix any critical issues
```

### B. Public Launch

```markdown
1. Community announcement
2. Social media campaign
3. Update all documentation
4. Monitor launch metrics
5. Provide user support
```

---

## 📋 PRODUCTION DEPLOYMENT COMMANDS SUMMARY

```bash
# 1. Switch to mainnet
solana config set --url mainnet-beta

# 2. Deploy program
anchor build --release
solana program deploy target/deploy/qup_staking_vault.so

# 3. Calculate addresses
export MAINNET_PROGRAM_ID="YOUR_PROGRAM_ID"
node mainnet_vault_init.js

# 4. Initialize vault
node initialize_mainnet_vault.js

# 5. Deploy frontend
git push production
# or deploy to production hosting

# 6. Test everything
# Comprehensive testing with real QUP tokens

# 7. Go live!
# Community announcement and launch
```

---

## ⚠️ CRITICAL SECURITY REMINDERS

1. **Test everything on devnet first**
2. **Use hardware wallets for production**
3. **Never share private keys**
4. **Audit all code before deployment**
5. **Start with small amounts**
6. **Have emergency procedures ready**
7. **Monitor constantly after launch**

---

## 📞 POST-DEPLOYMENT CHECKLIST

- [ ] Vault deployed and initialized
- [ ] Frontend recognizes QUP tokens properly  
- [ ] All staking functions work correctly
- [ ] Rewards calculate accurately
- [ ] Security monitoring active
- [ ] Community announcement sent
- [ ] User documentation updated
- [ ] Support channels ready

---

**Total Estimated Time:** 4-8 hours (including testing)  
**Total Estimated Cost:** 10-20 SOL (deployment + testing)  
**Risk Level:** HIGH (Real tokens and money involved)

**Next Steps After Devnet Validation:**
1. Complete devnet testing
2. Security audit
3. Follow this guide step by step
4. Soft launch with limited users
5. Full public launch

*This guide assumes successful devnet testing and covers the complete production deployment process for the QUP staking vault on Solana mainnet.*
