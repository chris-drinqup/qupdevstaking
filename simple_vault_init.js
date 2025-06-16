const { Connection, PublicKey, Keypair, Transaction, TransactionInstruction, clusterApiUrl } = require('@solana/web3.js');
const { TOKEN_PROGRAM_ID } = require('@solana/spl-token');
const fs = require('fs');

async function initializeVaultDirect() {
    try {
        console.log('🚀 Starting direct vault initialization...');
        
        // Connect to devnet
        const connection = new Connection(clusterApiUrl('devnet'), 'confirmed');
        console.log('✅ Connected to devnet');

        // Load wallet
        const walletPath = process.env.ANCHOR_WALLET || '~/.config/solana/id.json';
        const expandedPath = walletPath.replace('~', require('os').homedir());
        const walletKeypair = Keypair.fromSecretKey(
            new Uint8Array(JSON.parse(fs.readFileSync(expandedPath, 'utf8')))
        );
        console.log('✅ Wallet loaded:', walletKeypair.publicKey.toString());

        // Program and token addresses
        const programId = new PublicKey('69GqjmqyXcL593ByVF4YqrFzBxHX5DsVcSRsAk49pPq7');
        const qupdevMint = new PublicKey('8bjKA2mkXMdkUHC6m8TfyQcksTDLKeP61XmFFcVViYef');

        // Find vault PDA
        const [vaultPda, vaultBump] = PublicKey.findProgramAddressSync(
            [Buffer.from('vault'), walletKeypair.publicKey.toBuffer()],
            programId
        );
        console.log('✅ Vault PDA:', vaultPda.toString());
        console.log('✅ Vault Bump:', vaultBump);

        // Find token vault PDA
        const [tokenVaultPda, tokenVaultBump] = PublicKey.findProgramAddressSync(
            [Buffer.from('token_vault'), walletKeypair.publicKey.toBuffer()],
            programId
        );
        console.log('✅ Token Vault PDA:', tokenVaultPda.toString());
        console.log('✅ Token Vault Bump:', tokenVaultBump);

        // Check if vault already exists
        try {
            const vaultAccountInfo = await connection.getAccountInfo(vaultPda);
            if (vaultAccountInfo && vaultAccountInfo.data.length > 0) {
                console.log('⚠️  Vault already exists!');
                console.log('   Account Owner:', vaultAccountInfo.owner.toString());
                console.log('   Data Length:', vaultAccountInfo.data.length);
                
                // Try to read some basic data
                if (vaultAccountInfo.data.length >= 64) {
                    // Skip discriminator (8 bytes) and read authority (32 bytes)
                    const authorityBytes = vaultAccountInfo.data.slice(8, 40);
                    const authority = new PublicKey(authorityBytes);
                    console.log('   Authority:', authority.toString());
                }
                
                return {
                    status: 'exists',
                    vaultPda: vaultPda.toString(),
                    tokenVaultPda: tokenVaultPda.toString(),
                    programId: programId.toString()
                };
            }
        } catch (error) {
            console.log('✅ Vault does not exist, proceeding with initialization...');
        }

        // Check token vault
        const tokenVaultAccountInfo = await connection.getAccountInfo(tokenVaultPda);
        if (tokenVaultAccountInfo) {
            console.log('⚠️  Token vault already exists');
        }

        console.log('\n📋 Summary:');
        console.log('Program ID:', programId.toString());
        console.log('Authority:', walletKeypair.publicKey.toString());
        console.log('Token Mint:', qupdevMint.toString());
        console.log('Vault PDA:', vaultPda.toString());
        console.log('Token Vault PDA:', tokenVaultPda.toString());
        console.log('Vault Bump:', vaultBump);
        console.log('Token Vault Bump:', tokenVaultBump);

        // Save addresses for later use
        const addresses = {
            programId: programId.toString(),
            authority: walletKeypair.publicKey.toString(),
            qupdevMint: qupdevMint.toString(),
            vaultPda: vaultPda.toString(),
            tokenVaultPda: tokenVaultPda.toString(),
            vaultBump: vaultBump,
            tokenVaultBump: tokenVaultBump,
            status: 'ready_for_init'
        };

        fs.writeFileSync('./vault_addresses.json', JSON.stringify(addresses, null, 2));
        console.log('\n✅ Addresses saved to vault_addresses.json');

        console.log('\n🎯 Next Steps:');
        console.log('1. The vault PDAs have been calculated and saved');
        console.log('2. Use Anchor CLI or a frontend to call the initialize_vault instruction');
        console.log('3. Or use the testing script with these addresses');

        return addresses;

    } catch (error) {
        console.error('❌ Error:', error);
        throw error;
    }
}

// Run the script
if (require.main === module) {
    initializeVaultDirect()
        .then((result) => {
            if (result.status === 'exists') {
                console.log('\n🎉 Vault already exists and is ready for testing!');
            } else {
                console.log('\n🎉 Vault addresses calculated and saved!');
                console.log('Use these addresses with Anchor CLI or your frontend to initialize the vault.');
            }
        })
        .catch((error) => {
            console.error('Failed:', error);
            process.exit(1);
        });
}

module.exports = { initializeVaultDirect };
