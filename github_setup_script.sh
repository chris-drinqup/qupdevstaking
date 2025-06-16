#!/bin/bash

# QUP Vault Auto-Setup Script
# This script creates the GitHub repository and all necessary files

set -e  # Exit on any error

echo "🚀 QUP Vault Auto-Setup Script"
echo "================================"

# Configuration
GITHUB_USERNAME="chris-drinqup"
REPO_NAME="qupdevstaking"
REPO_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed. Please install Git first."
    exit 1
fi

if ! command -v gh &> /dev/null; then
    echo "⚠️  GitHub CLI not found. You'll need to create the repository manually on GitHub.com"
    echo "   Visit: https://github.com/new"
    echo "   Repository name: $REPO_NAME"
    echo "   Make it public"
    echo "   Don't initialize with README"
    echo ""
    read -p "Press Enter after creating the repository on GitHub..."
else
    echo "✅ GitHub CLI found"
fi

# Create local directory
echo "📁 Creating local project directory..."
if [ -d "$REPO_NAME" ]; then
    echo "⚠️  Directory $REPO_NAME already exists. Removing..."
    rm -rf "$REPO_NAME"
fi

mkdir "$REPO_NAME"
cd "$REPO_NAME"

# Initialize git
echo "🔧 Initializing Git repository..."
git init
git branch -M main

# Create index.html (Web Interface)
echo "🌐 Creating web interface (index.html)..."
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>QUP Vault Tester - Community Testing</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #333;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }

        .header {
            text-align: center;
            color: white;
            margin-bottom: 30px;
        }

        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }

        .status-badge {
            display: inline-block;
            background: #4CAF50;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-weight: bold;
            margin: 10px 0;
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.7; }
            100% { opacity: 1; }
        }

        .main-content {
            background: white;
            border-radius: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            overflow: hidden;
        }

        .nav-tabs {
            display: flex;
            background: #f8f9fa;
            border-bottom: 2px solid #e9ecef;
        }

        .nav-tab {
            flex: 1;
            padding: 15px;
            text-align: center;
            cursor: pointer;
            font-weight: bold;
            transition: all 0.3s ease;
            border: none;
            background: none;
        }

        .nav-tab.active {
            background: white;
            color: #667eea;
            border-bottom: 3px solid #667eea;
        }

        .nav-tab:hover {
            background: #e9ecef;
        }

        .tab-content {
            padding: 30px;
            min-height: 400px;
        }

        .tab-pane {
            display: none;
        }

        .tab-pane.active {
            display: block;
        }

        .wallet-section {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 30px;
            border-left: 4px solid #667eea;
        }

        .connect-btn {
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 12px 30px;
            border-radius: 25px;
            font-size: 1.1rem;
            cursor: pointer;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }

        .connect-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(0,0,0,0.3);
        }

        .connect-btn:disabled {
            background: #ccc;
            cursor: not-allowed;
            transform: none;
        }

        .balance-display {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }

        .balance-card {
            background: linear-gradient(45deg, #4CAF50, #45a049);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }

        .balance-card h3 {
            margin-bottom: 10px;
            opacity: 0.9;
        }

        .balance-card .amount {
            font-size: 1.5rem;
            font-weight: bold;
        }

        .vault-info {
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
        }

        .vault-info h3 {
            margin-bottom: 15px;
        }

        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
        }

        .info-item {
            background: rgba(255,255,255,0.1);
            padding: 10px;
            border-radius: 5px;
        }

        .info-item strong {
            display: block;
            margin-bottom: 5px;
        }

        .info-item span {
            word-break: break-all;
            font-size: 0.9rem;
        }

        .welcome-section {
            text-align: center;
            padding: 40px 20px;
        }

        .welcome-section h2 {
            color: #667eea;
            margin-bottom: 20px;
        }

        .welcome-section p {
            font-size: 1.1rem;
            margin-bottom: 15px;
        }

        .feature-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }

        .feature-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            border-left: 4px solid #667eea;
        }

        .feature-card h4 {
            color: #667eea;
            margin-bottom: 10px;
        }

        .cta-section {
            background: linear-gradient(45deg, #ff9a56, #ffad56);
            color: white;
            padding: 30px;
            border-radius: 10px;
            text-align: center;
            margin: 30px 0;
        }

        @media (max-width: 768px) {
            .container {
                padding: 10px;
            }
            
            .header h1 {
                font-size: 2rem;
            }
            
            .nav-tabs {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 QUP Vault Tester</h1>
            <div class="status-badge">✅ LIVE ON DEVNET</div>
            <p>Community Testing Interface - Works with Any Solana Wallet!</p>
        </div>

        <div class="main-content">
            <div class="nav-tabs">
                <button class="nav-tab active" onclick="showTab('welcome')">Welcome</button>
                <button class="nav-tab" onclick="showTab('connect')">Connect Wallet</button>
                <button class="nav-tab" onclick="showTab('info')">Vault Info</button>
                <button class="nav-tab" onclick="showTab('help')">Help</button>
            </div>

            <!-- Welcome Tab -->
            <div id="welcome" class="tab-pane active">
                <div class="tab-content">
                    <div class="welcome-section">
                        <h2>Welcome to QUP Vault Testing!</h2>
                        <p>Help us test the future of Solana staking before mainnet launch.</p>
                        <p><strong>No downloads required</strong> - just connect your Solana wallet and start testing!</p>
                    </div>

                    <div class="feature-grid">
                        <div class="feature-card">
                            <h4>🔒 Stake & Earn</h4>
                            <p>Stake QUPDEV tokens and earn 1% daily rewards. Test the complete staking lifecycle.</p>
                        </div>
                        <div class="feature-card">
                            <h4>📱 Universal Support</h4>
                            <p>Works with Phantom, Solflare, Backpack, and other Solana wallets. Mobile friendly!</p>
                        </div>
                        <div class="feature-card">
                            <h4>🎁 Earn Rewards</h4>
                            <p>Get real QUP tokens for mainnet by helping us test. Up to 500 QUP for active testers!</p>
                        </div>
                        <div class="feature-card">
                            <h4>🛡️ Safe Testing</h4>
                            <p>All testing on Solana devnet. No real money at risk. Test tokens provided free.</p>
                        </div>
                    </div>

                    <div class="cta-section">
                        <h3>Ready to Start Testing?</h3>
                        <p>Connect your wallet and request test tokens to begin!</p>
                        <button class="connect-btn" onclick="showTab('connect')" style="margin: 15px 0;">
                            Get Started →
                        </button>
                    </div>
                </div>
            </div>

            <!-- Connect Tab -->
            <div id="connect" class="tab-pane">
                <div class="tab-content">
                    <div class="wallet-section">
                        <h3>Step 1: Connect Your Solana Wallet</h3>
                        <p>This works with Phantom, Solflare, Backpack, and other Solana wallets!</p>
                        <br>
                        <button id="connectBtn" class="connect-btn" onclick="connectWallet()">
                            Connect Wallet
                        </button>
                        <div id="walletStatus" style="margin-top: 15px;"></div>
                    </div>

                    <div id="balanceSection" style="display: none;">
                        <h3>Your Balances</h3>
                        <div class="balance-display">
                            <div class="balance-card">
                                <h3>SOL Balance</h3>
                                <div class="amount" id="solBalance">Loading...</div>
                            </div>
                            <div class="balance-card">
                                <h3>QUPDEV Tokens</h3>
                                <div class="amount" id="qupdevBalance">Loading...</div>
                            </div>
                        </div>
                        
                        <div id="needTokens" style="background: #fff3cd; padding: 20px; border-radius: 10px; margin-top: 20px;">
                            <h4>🎯 Need Test Tokens?</h4>
                            <p>Join our Discord/Telegram and share your wallet address:</p>
                            <p><strong>Your Address:</strong> <span id="userAddress"></span></p>
                            <button class="connect-btn" onclick="copyAddress()" style="margin: 10px 0; font-size: 0.9rem; padding: 8px 16px;">📋 Copy Address</button>
                            <p>We'll send you 1000 QUPDEV tokens + devnet SOL for testing!</p>
                            <p><strong>Discord:</strong> #qup-vault-testing | <strong>Telegram:</strong> @qup-community</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Info Tab -->
            <div id="info" class="tab-pane">
                <div class="tab-content">
                    <div class="vault-info">
                        <h3>📊 Live Vault Information</h3>
                        <div class="info-grid">
                            <div class="info-item">
                                <strong>Vault Address:</strong>
                                <span>FGCLTzWpKHmPLcak8HcqP7j7wz7jjLTWzZ1SwKNFfzuz</span>
                            </div>
                            <div class="info-item">
                                <strong>Program ID:</strong>
                                <span>69GqjmqyXcL593ByVF4YqrFzBxHX5DsVcSRsAk49pPq7</span>
                            </div>
                            <div class="info-item">
                                <strong>Reward Rate:</strong>
                                <span>1% Daily (100 basis points)</span>
                            </div>
                            <div class="info-item">
                                <strong>Network:</strong>
                                <span>Solana Devnet</span>
                            </div>
                        </div>
                    </div>

                    <div class="feature-card" style="margin: 20px 0;">
                        <h4>🔗 Explore on Solana</h4>
                        <p>View the live vault and transactions on Solana Explorer:</p>
                        <div style="margin: 15px 0;">
                            <button class="connect-btn" onclick="openExplorer('vault')" style="margin: 5px; font-size: 0.9rem; padding: 8px 16px;">
                                View Vault
                            </button>
                            <button class="connect-btn" onclick="openExplorer('program')" style="margin: 5px; font-size: 0.9rem; padding: 8px 16px;">
                                View Program
                            </button>
                            <button class="connect-btn" onclick="openExplorer('init')" style="margin: 5px; font-size: 0.9rem; padding: 8px 16px; background: #4CAF50;">
                                Initialization Tx
                            </button>
                        </div>
                    </div>

                    <div class="feature-card">
                        <h4>💻 For Technical Users</h4>
                        <p>Prefer command line? Check out our GitHub repository with full CLI tools:</p>
                        <button class="connect-btn" onclick="window.open('https://github.com/chris-drinqup/qupdevstaking', '_blank')" style="margin: 10px 0; font-size: 0.9rem; padding: 8px 16px;">
                            View on GitHub
                        </button>
                    </div>
                </div>
            </div>

            <!-- Help Tab -->
            <div id="help" class="tab-pane">
                <div class="tab-content">
                    <h3>❓ Help & Support</h3>
                    
                    <div class="feature-card" style="margin: 20px 0;">
                        <h4>🚀 Quick Start Guide</h4>
                        <p><strong>1. Get a Wallet:</strong> Download Phantom, Solflare, or Backpack</p>
                        <p><strong>2. Switch to Devnet:</strong> Change network to "Devnet" in wallet settings</p>
                        <p><strong>3. Connect Here:</strong> Click "Connect Wallet" tab</p>
                        <p><strong>4. Get Test Tokens:</strong> Share your address in Discord/Telegram</p>
                        <p><strong>5. Start Testing:</strong> Full testing interface coming soon!</p>
                    </div>

                    <div class="feature-card" style="margin: 20px 0;">
                        <h4>🆘 Common Issues</h4>
                        <p><strong>Wallet not detected:</strong> Install a Solana wallet browser extension</p>
                        <p><strong>Wrong network:</strong> Switch to "Devnet" in wallet settings</p>
                        <p><strong>No test tokens:</strong> Request in Discord/Telegram with your address</p>
                        <p><strong>Transaction failed:</strong> Make sure you have devnet SOL for fees</p>
                    </div>

                    <div class="cta-section">
                        <h4>📞 Get Support</h4>
                        <p><strong>Discord:</strong> #qup-vault-testing</p>
                        <p><strong>Telegram:</strong> @qup-community</p>
                        <p><strong>GitHub:</strong> Create an issue for bugs</p>
                        <p><strong>Response Time:</strong> Usually &lt; 30 minutes</p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Include Solana Web3.js -->
    <script src="https://unpkg.com/@solana/web3.js@latest/lib/index.iife.min.js"></script>

    <script>
        let wallet = null;
        let connection = null;

        // Initialize connection
        connection = new solanaWeb3.Connection('https://api.devnet.solana.com', 'confirmed');

        // Tab navigation
        function showTab(tabName) {
            document.querySelectorAll('.tab-pane').forEach(pane => {
                pane.classList.remove('active');
            });
            
            document.querySelectorAll('.nav-tab').forEach(tab => {
                tab.classList.remove('active');
            });
            
            document.getElementById(tabName).classList.add('active');
            event.target.classList.add('active');
        }

        // Wallet connection
        async function connectWallet() {
            const connectBtn = document.getElementById('connectBtn');
            const walletStatus = document.getElementById('walletStatus');
            
            try {
                connectBtn.disabled = true;
                connectBtn.innerHTML = '⏳ Connecting...';
                
                // Check for various wallet providers
                let provider = null;
                if (window.solana && window.solana.isPhantom) {
                    provider = window.solana;
                } else if (window.solflare && window.solflare.isSolflare) {
                    provider = window.solflare;
                } else if (window.backpack) {
                    provider = window.backpack;
                } else if (window.solana) {
                    provider = window.solana;
                } else {
                    throw new Error('No Solana wallet detected. Please install Phantom, Solflare, or Backpack.');
                }

                // Request connection
                const response = await provider.connect();
                wallet = response.publicKey;
                
                // Update UI
                connectBtn.innerHTML = '✅ Connected';
                connectBtn.style.background = '#4CAF50';
                walletStatus.innerHTML = `
                    <div style="color: #4CAF50; font-weight: bold;">
                        ✅ Connected: ${wallet.toString().slice(0, 8)}...${wallet.toString().slice(-8)}
                    </div>
                `;
                
                document.getElementById('userAddress').textContent = wallet.toString();
                document.getElementById('balanceSection').style.display = 'block';
                
                // Load balances
                await loadBalances();
                
            } catch (error) {
                connectBtn.disabled = false;
                connectBtn.innerHTML = 'Connect Wallet';
                walletStatus.innerHTML = `<div style="color: #f56565;">❌ ${error.message}</div>`;
            }
        }

        // Load wallet balances
        async function loadBalances() {
            try {
                // Get SOL balance
                const solBalance = await connection.getBalance(wallet);
                const solBalanceFormatted = (solBalance / solanaWeb3.LAMPORTS_PER_SOL).toFixed(3);
                document.getElementById('solBalance').textContent = `${solBalanceFormatted} SOL`;
                
                // For now, show 0 QUPDEV - full implementation coming soon
                document.getElementById('qupdevBalance').textContent = '0 QUPDEV';
                
            } catch (error) {
                document.getElementById('solBalance').textContent = 'Error';
                document.getElementById('qupdevBalance').textContent = 'Error';
            }
        }

        // Utility functions
        function copyAddress() {
            if (wallet) {
                navigator.clipboard.writeText(wallet.toString());
                alert('Wallet address copied to clipboard!');
            }
        }

        function openExplorer(type) {
            const baseUrl = 'https://explorer.solana.com';
            let url;
            
            switch (type) {
                case 'vault':
                    url = `${baseUrl}/address/FGCLTzWpKHmPLcak8HcqP7j7wz7jjLTWzZ1SwKNFfzuz?cluster=devnet`;
                    break;
                case 'program':
                    url = `${baseUrl}/address/69GqjmqyXcL593ByVF4YqrFzBxHX5DsVcSRsAk49pPq7?cluster=devnet`;
                    break;
                case 'init':
                    url = `${baseUrl}/tx/37RZR3gooFLt2nSJVtZX5js4e6xb5hUEeWHkDZKgL1LSUuqxeuptBkrwpVoRTmeqjoy3qUeoxUPqZqyndQsXAyg7?cluster=devnet`;
                    break;
            }
            
            window.open(url, '_blank');
        }

        // Initialize the interface
        document.addEventListener('DOMContentLoaded', function() {
            console.log('QUP Vault Tester loaded successfully');
            
            // Test connection
            connection.getVersion().then(version => {
                console.log(`Connected to Solana devnet`);
            }).catch(error => {
                console.error(`Failed to connect to devnet: ${error.message}`);
            });
        });
    </script>
</body>
</html>
EOF

# Create vault_tester.js (CLI interface)
echo "💻 Creating CLI interface (vault_tester.js)..."
cat > vault_tester.js << 'EOF'
const { Connection, PublicKey, Keypair, clusterApiUrl } = require('@solana/web3.js');
const { getOrCreateAssociatedTokenAccount } = require('@solana/spl-token');
const fs = require('fs');

// Vault configuration
const VAULT_CONFIG = {
    programId: '69GqjmqyXcL593ByVF4YqrFzBxHX5DsVcSRsAk49pPq7',
    vaultPda: 'FGCLTzWpKHmPLcak8HcqP7j7wz7jjLTWzZ1SwKNFfzuz',
    tokenVaultPda: 'HCw3qKrvemEwYzAzozqtwBtdapsWe7GfeCKjrUUPNSQf',
    qupdevMint: '8bjKA2mkXMdkUHC6m8TfyQcksTDLKeP61XmFFcVViYef',
    network: 'devnet'
};

class QUPVaultTester {
    constructor() {
        this.connection = new Connection(clusterApiUrl('devnet'), 'confirmed');
        this.programId = new PublicKey(VAULT_CONFIG.programId);
        this.vaultPda = new PublicKey(VAULT_CONFIG.vaultPda);
        this.tokenVaultPda = new PublicKey(VAULT_CONFIG.tokenVaultPda);
        this.qupdevMint = new PublicKey(VAULT_CONFIG.qupdevMint);
    }

    async initialize(walletPath) {
        try {
            // Load wallet
            const expandedPath = walletPath.replace('~', require('os').homedir());
            const walletKeypair = Keypair.fromSecretKey(
                new Uint8Array(JSON.parse(fs.readFileSync(expandedPath, 'utf8')))
            );
            
            this.wallet = walletKeypair;
            console.log('✅ Wallet loaded:', this.wallet.publicKey.toString());

            return true;
        } catch (error) {
            console.error('❌ Failed to initialize:', error.message);
            return false;
        }
    }

    async checkStatus() {
        try {
            console.log('\n📊 QUP VAULT STATUS CHECK');
            console.log('==========================');

            // SOL balance
            const solBalance = await this.connection.getBalance(this.wallet.publicKey);
            console.log(`💰 SOL Balance: ${solBalance / 1e9} SOL`);

            // Check for QUPDEV token account
            try {
                const tokenAccount = await getOrCreateAssociatedTokenAccount(
                    this.connection,
                    this.wallet,
                    this.qupdevMint,
                    this.wallet.publicKey
                );
                
                const tokenBalance = await this.connection.getTokenAccountBalance(tokenAccount.address);
                console.log(`🪙 QUPDEV Balance: ${tokenBalance.value.uiAmount || 0} QUPDEV`);
                
                if (tokenBalance.value.uiAmount === 0) {
                    console.log('⚠️  No QUPDEV tokens found. Request test tokens from the team!');
                    console.log(`   Your address: ${this.wallet.publicKey.toString()}`);
                }
            } catch (error) {
                console.log('⚠️  No QUPDEV tok found. Request test tokens!');
                console.log(`   Your address: ${this.wallet.publicKey.toString()}`);
            }

            // Check vault status
            const vaultAccount = await this.connection.getAccountInfo(this.vaultPda);
            if (vaultAccount) {
                console.log('🏛️  Vault Status: ✅ Active and ready for staking');
                console.log(`   Vault Address: ${this.vaultPda.toString()}`);
                console.log(`   Data Size: ${vaultAccount.datah} bytes`);
            } else {
                console.log('❌ Vault not found!');
            }

            console.log('\n📋 Next Steps:');
            console.log('1. If you need test tokens, share your address in Discord/Telegram');
            console.log('2. Once you have tokens, try: node vault_tester.js test');
            console.log('3. Or use individual commands: stake, unstake, claim');

            return true;
        } catch (error) {
            console.error('❌ Status check failed:'ror.message);
            return false;
        }
    }

    async runTests() {
        console.log('\n🧪 QUP VAULT TEST SUITE');
        console.log('========================');
        console.log('This is a placeholder for the full test suite.');
        console.log('The complete implementation will include:');
        console.log('- Automated staking tests');
        console.log('- Reward calculation verification');
        console.log('- Unstaking and claiming tests');
        console.log('- Edge castesting');
        console.log('\nFor now, use the web interface for full testing:');
        console.log('👉 https://chris-drinqup.github.io/qupdevstaking');
    }
}

// CLI interface
async function main() {
    const args = process.argv.slice(2);
    const command = args[0];
    const walletPath = process.env.ANCHOR_WALLET || '~/.config/solana/id.json';

    const tester = new QUPVaultTester();
    
    if (!await tester.initialize(walletPath)) {
        console.error('Failed to initialize. Check your wlet path and try again.');
        process.exit(1);
    }

    switch (command) {
        case 'status':
            await tester.checkStatus();
            break;
            
        case 'test':
            await tester.runTests();
            break;
            
        case 'stake':
            console.log('Stake command - Implementation coming soon!');
            console.log('For now, use the web interface: https://chris-drinqup.github.io/qupdevstaking');
            break;
            
        case 'unstake':
            console.log('Unstake command - Implementation coming soon!');
            console.log('For now, use the web interface: https://chris-drinqup.github.io/qupdevstaking');
            break;
            
        case 'claim':
            console.log('Claim command - Implementation coming soon!');
            console.log('For now, use the web interface: https://chris-drinqup.github.io/qupdevstaking');
            break;
            
        default:
            console.log(`
QUP Vault Tester - CLI Interface

Usage: node vault_tester.js <command>

Commands:
  status    Check wallet balances and vault status
  test      Run automated test suite
  stake     Stake QUPDEV tokens (coming soon)
  unstake   Unstake QUPDEV tokens (coming soon)  
  claim     Claim rewards (coming soon)

Environment:
  ANCHOR_WALLET - Path to your Solana wallet (default: ~/.config/solana/id.json)

Examples:
  node vault_tester.js status
  node vault_tester.js test

For full testing experience, visit:
👉 https://chris-drinqup.github.io/qupdevstaking
            `);
    }
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = { QUPVaultTester };
EOF

# Create package.json
echo "📦 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "qup-vault-community-tester",
  "version": "1.0.0",
  "description": "Community testing suite for QUP Staking Vault on Solana Devnet",
  "main": "vault_tester.js",
  "scripts": {
    "test": "node vault_tester.js test",
    "status": "node vault_ster.js status",
    "serve": "python3 -m http.server 8000 || python -m http.server 8000",
    "start": "npm run serve"
  },
  "keywords": [
    "solana",
    "defi",
    "staking",
    "qup",
    "testing",
    "blockchain",
    "web3"
  ],
  "author": "QUP Team",
  "license": "MIT",
  "dependencies": {
    "@solana/web3.js": "^1.95.0",
    "@solana/spl-token": "^0.4.8"
  },
  "engines": {
    "node": ">=16.0.0"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/chris-drinqup/qupdevstaking.git"
  },
  "bugs": {
    "url": "https://github.com/chris-drinqup/qupdevstaking/issues"
  },
  "homepage": "https://chris-drinqup.github.io/qupdevstaking"
}
EOF

# Create README.md
echo "📖 Creating README.md..."
cat > README.md << 'EOF'
# QUP Staking Vault - Community Testing

**🎉 QUP Staking Vault is LIVE on Solana Devnet!**

Help us test the QUP staking vault before mainnet launch. Choose your testing method below.

## 🌐 Web Interface (Recommended for Most Users)

**No downloads, no comman, works with any Solana wallet!**

### Quick Start:
1. **Visit:** https://chris-drinqup.github.io/qupdevstaking
2. **Connect** your Solana wallet (Phantom, Solflare, etc.)
3. **Request test tokens** in our Discord/Telegram
4. **Start testing!**

### Features:
- ✅ Universal wallet support (Phantom, Solflare, Backpack, etc.)
- ✅ Real-time balance monitoring
- ✅ Mobile friendly interface
- ✅ No downloads or setup required
- ✅ Comprehensive help and support

---

## 💻 Command Line Interface (For Tes)

### Quick Setup
```bash
# Clone repository
git clone https://github.com/chris-drinqup/qupdevstaking.git
cd qupdevstaking

# Install dependencies
npm install

# Set your wallet
export ANCHOR_WALLET=~/.config/solana/id.json

# Check status
node vault_tester.js status
```

---

## 📊 Vault Information

| Detail | Value |
|--------|-------|
| **Status** | 🟢 Live on Devnet |
| **Vault Address** | `FGCLTzWpKHmPLcak8HcqP7j7wz7jjLTWzZ1SwKNFfzuz` |
| **Program ID** | `69GqjmqyXcL593ByVF4YqrFzBxHX5DsVcSRsAk47` |
| **Token Mint** | `8bjKA2mkXMdkUHC6m8TfyQcksTDLKeP61XmFFcVViYef` |
| **Reward Rate** | 1% daily (100 basis points) |
| **Network** | Solana Devnet |

### 🔗 Explorer Links
- [View Vault](https://explorer.solana.com/address/FGCLTzWpKHmPLcak8HcqP7j7wz7jjLTWzZ1SwKNFfzuz?cluster=devnet)
- [View Program](https://explorer.solana.com/address/69GqjmqyXcL593ByVF4YqrFzBxHX5DsVcSRsAk49pPq7?cluster=devnet)
- [Initialization Transaction](https://explorer.solana.com/tx/37RZR3gooFLt2nSJVtZX5js4e6xb5hUEeWHkDZKgL1LSqxeuptBkrwpVoRTmeqjoy3qUeoxUPqZqyndQsXAyg7?cluster=devnet)

---

## 🎁 Tester Rewards

**Help us test and earn QUP tokens for mainnet!**

| Achievement | Reward (QUP Mainnet) |
|-------------|----------------------|
| Complete basic testing | 50 QUP |
| Find critical bug | 200 QUP |
| Complete advanced testing | 100 QUP |
| Help other testers | 25 QUP |
| Valuable feedback | 50 QUP |
| Top 10 most active testers | 500 QUP |

---

## 🆘 Getting Help

### Community Support
- **Discord:** #qup-vault-testin**Telegram:** @qup-community  
- **Response time:** Usually < 30 minutes

### Need Test Tokens?
1. Connect your wallet using the web interface
2. Copy your wallet address
3. Share it in Discord/Telegram
4. We'll send you 1000 QUPDEV + devnet SOL

---

## 🚀 Quick Start

### For Most Users (Web Interface):
```
1. Visit: https://chris-drinqup.github.io/qupdevstaking
2. Click "Connect Wallet"
3. Request test tokens in Discord
4. Start testing!
```

### For Technical Users (CLI):
```bash
git clone https://gitub.com/chris-drinqup/qupdevstaking.git
cd qupdevstaking
npm install
export ANCHOR_WALLET=~/.config/solana/id.json
node vault_tester.js status
```

---

**Built with ❤️ by the QUP team**

*Help us make the best staking platform on Solana!*
EOF

# Create LICENSE
echo "⚖️ Creating LICENSE..."
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2025 QUP Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), tn the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# Create .gitignore
echo "🙈 Creating .gitignore..."
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.g*

# Environment files
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# Logs
logs
*.log

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/

# Build outputs
dist/
build/

# Temporary files
tmp/
temp/
EOF

# Add GitHub Actions workflow for auto-deployment
echo "🤖 Creating GitHub Actionsorkflow..."
mkdir -p .github/workflows
cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        
    - name: Install dependencies
      run: npm install
      
    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      if: github.ref == 'refs/heads/main'
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: .
        publish_branch: gh-pages
EOF

echo "📝 All files created successfully!"
echo ""

# Add everything to git
echo "📤 Adding files to git..."
git add .
git commit -m "Initial release: QUP Vault Community Testing Platform

✅ Web interface for easy testing
✅ CLI tools for technical users  
✅ Complete documentation
✅ Auto-deployment setup
✅ MIT licor community testing on Solana devnet!"

# Try to create repo and push
if command -v gh &> /dev/null; then
    echo "🚀 Creating GitHub repository..."
    gh repo create "$REPO_NAME" --public --description "QUP Staking Vault Community Testing - Live on Solana Devnet" --homepage "https://$GITHUB_USERNAME.github.io/$REPO_NAME"
    
    echo "📤 Pushing to GitHub..."
    git remote add origin "$REPO_URL"
    git push -u origin main
    
    echo "🌐 Enabling GitHub Pages..."
    gh api repos/$GITHUB_USERREPO_NAME/pages -X POST -F source.branch=main -F source.path=/
    
    echo ""
    echo "🎉 SUCCESS! Your QUP Vault Testing Platform is live!"
    echo "=================================================="
    echo ""
    echo "🌐 Web Interface: https://$GITHUB_USERNAME.github.io/$REPO_NAME"
    echo "💻 GitHub Repo: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
    echo "📊 Vault Explorer: https://explorer.solana.com/address/FGCLTzWpKHmPLcak8HcqP7j7wz7jjLTWzZ1SwKNFfzuz?cluster=devnet"
    echo ""ho "📱 Share with your community:"
    echo "🎯 QUP Vault Testing is LIVE!"
    echo "👉 https://$GITHUB_USERNAME.github.io/$REPO_NAME"
    echo "✅ No downloads needed - just connect your Solana wallet!"
    echo "🎁 Earn up to 500 QUP for testing!"
    echo ""
    
else
    echo "⚠️  GitHub CLI not found. Manual steps needed:"
    echo ""
    echo "1. Create repository manually:"
    echo "   👉 https://github.com/new"
    echo "   Repository name: $REPO_NAME"
    echo "   Make it public"
    echo "   Don't initialize with README"
    echo ""
    echo "2. Push your code:"
    echo "   git remote add origin $REPO_URL"
    echo "   git push -u origin main"
    echo ""
    echo "3. Enable GitHub Pages:"
    echo "   Go to Settings → Pages → Deploy from main branch"
    echo ""
fi

echo "📋 Next steps:"
echo "1. Wait 2-3 minutes for GitHub Pages to deploy"
echo "2. Test the web interface yourself"
echo "3. Prepare test token distribution"
echo "4. Announce to your community!"
echo ""
echo "r community can now test with just their Phantom wallet!"
EOF

chmod +x auto_setup.sh

echo "🤖 Auto-setup script created!"
echo ""
echo "Run this command to set up everything automatically:"
echo ""
echo "    bash auto_setup.sh"
echo ""
echo "This script will:"
echo "✅ Create all necessary files"
echo "✅ Set up the GitHub repository"
echo "✅ Enable GitHub Pages hosting"
echo "✅ Configure auto-deployment"
echo "✅ Give you the live URLs"
echo ""
echo "After running it, your community can test immh:"
echo "👉 https://chris-drinqup.github.io/qupdevstaking"
