const anchor = require('@coral-xyz/anchor');
const { Connection, PublicKey, Keypair, clusterApiUrl } = require('@solana/web3.js');
const { TOKEN_PROGRAM_ID } = require('@solana/spl-token');
const fs = require('fs');

async function testInitialization() {
    try {
        // Load the addresses we calculated
        const addresses = JSON.parse(fs.readFileSync('./vault_addresses.json', 'utf8'));
        console.log('📁 Loaded addresses:', addresses);

        // Connect to devnet
        const connection = new Connection(clusterApiUrl('devnet'), 'confirmed');
        
        // Load wallet
        const walletPath = process.env.ANCHOR_WALLET || '~/.config/solana/id.json';
        const expandedPath = walletPath.replace('~', require('os').homedir());
        const walletKeypair = Keypair.fromSecretKey(
            new Uint8Array(JSON.parse(fs.readFileSync(expandedPath, 'utf8')))
        );
        
        console.log('🚀 Attempting to initialize vault with calculated addresses...');
        console.log('Vault PDA:', addresses.vaultPda);
        console.log('Token Vault PDA:', addresses.tokenVaultPda);
        console.log('Authority:', addresses.authority);
        console.log('Vault Bump:', addresses.vaultBump);

        // Try to call the program directly using the addresses
        // For now, let's just verify the accounts exist and are accessible
        
        const vaultPda = new PublicKey(addresses.vaultPda);
        const tokenVaultPda = new PublicKey(addresses.tokenVaultPda);
        
        // Check if vault exists
        const vaultInfo = await connection.getAccountInfo(vaultPda);
        console.log('Vault account info:', vaultInfo ? 'EXISTS' : 'DOES NOT EXIST');
        
        // Check if token vault exists  
        const tokenVaultInfo = await connection.getAccountInfo(tokenVaultPda);
        console.log('Token vault account info:', tokenVaultInfo ? 'EXISTS' : 'DOES NOT EXIST');
        
        if (!vaultInfo) {
            console.log('\n✅ Ready to initialize vault!');
            console.log('Run this command to initialize:');
            console.log(`anchor test -- --grep "initialize"`);
            console.log('\nOr use a frontend/testing script to call initialize_vault with these parameters:');
            console.log('- vault:', addresses.vaultPda);
            console.log('- authority:', addresses.authority);
            console.log('- tokenMint:', addresses.qupdevMint);
            console.log('- tokenVault:', addresses.tokenVaultPda);
            console.log('- bump:', addresses.vaultBump);
        } else {
            console.log('\n⚠️  Vault already exists! Ready for testing staking functions.');
        }

    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

testInitialization();
