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
