const anchor = require('@coral-xyz/anchor');
const { PublicKey, Keypair, Connection, clusterApiUrl } = require('@solana/web3.js');
const { TOKEN_PROGRAM_ID, getOrCreateAssociatedTokenAccount } = require('@solana/spl-token');
const fs = require('fs');

async function initializeVault() {
    try {
        // Connect to devnet
        const connection = new Connection(clusterApiUrl('devnet'), 'confirmed');
        console.log('✅ Connected to devnet');

        // Load wallet from file
        const walletPath = process.env.ANCHOR_WALLET || '~/.config/solana/id.json';
        const expandedPath = walletPath.replace('~', require('os').homedir());
        const walletKeypair = Keypair.fromSecretKey(
            new Uint8Array(JSON.parse(fs.readFileSync(expandedPath, 'utf8')))
        );
        
        const wallet = new anchor.Wallet(walletKeypair);
        const provider = new anchor.AnchorProvider(connection, wallet, {
            commitment: 'confirmed'
        });
        anchor.setProvider(provider);
        console.log('✅ Wallet loaded:', wallet.publicKey.toString());

        // Your deployed program ID (from your logs)
        const programId = new PublicKey('69GqjmqyXcL593ByVF4YqrFzBxHX5DsVcSRsAk49pPq7');
        
        // Load IDL
        const idl = JSON.parse(fs.readFileSync('./target/idl/new_qup_staking.json', 'utf8'));
        const program = new anchor.Program(idl, programId, provider);
        console.log('✅ Program loaded');

        // Your QUPDEV token mint address (from your logs)
        const qupdevMint = new PublicKey('8bjKA2mkXMdkUHC6m8TfyQcksTDLKeP61XmFFcVViYef');

        // Find vault PDA
        const [vaultPda, vaultBump] = PublicKey.findProgramAddressSync(
            [Buffer.from('vault'), wallet.publicKey.toBuffer()],
            programId
        );
        console.log('✅ Vault PDA:', vaultPda.toString());

        // Find token vault PDA
        const [tokenVaultPda, tokenVaultBump] = PublicKey.findProgramAddressSync(
            [Buffer.from('token_vault'), wallet.publicKey.toBuffer()],
            programId
        );
        console.log('✅ Token Vault PDA:', tokenVaultPda.toString());

        // Check if vault already exists
        try {
            const existingVault = await program.account.vault.fetch(vaultPda);
            console.log('⚠️  Vault already exists with total staked:', existingVault.totalStaked.toString());
            console.log('Vault details:', {
                authority: existingVault.authority.toString(),
                tokenMint: existingVault.tokenMint.toString(),
                totalStaked: existingVault.totalStaked.toString(),
                rewardRate: existingVault.rewardRate.toString()
            });
            return { vaultPda, tokenVaultPda, programId };
        } catch (err) {
            console.log('✅ Vault does not exist yet, proceeding with initialization...');
        }

        // Initialize the vault
        console.log('🚀 Initializing vault...');
        const tx = await program.methods
            .initializeVault(vaultBump)
            .accounts({
                vault: vaultPda,
                authority: wallet.publicKey,
                tokenMint: qupdevMint,
                tokenVault: tokenVaultPda,
                tokenProgram: TOKEN_PROGRAM_ID,
                systemProgram: anchor.web3.SystemProgram.programId,
                rent: anchor.web3.SYSVAR_RENT_PUBKEY,
            })
            .rpc();

        console.log('✅ Vault initialized successfully!');
        console.log('Transaction signature:', tx);
        console.log('Vault PDA:', vaultPda.toString());
        console.log('Token Vault PDA:', tokenVaultPda.toString());

        // Verify initialization
        const vault = await program.account.vault.fetch(vaultPda);
        console.log('📊 Vault Details:', {
            authority: vault.authority.toString(),
            tokenMint: vault.tokenMint.toString(),
            tokenVault: vault.tokenVault.toString(),
            totalStaked: vault.totalStaked.toString(),
            rewardRate: vault.rewardRate.toString() + ' basis points per day (1%)',
            lastUpdateTime: new Date(vault.lastUpdateTime * 1000).toISOString()
        });

        return { vaultPda, tokenVaultPda, programId };

    } catch (error) {
        console.error('❌ Error initializing vault:', error);
        throw error;
    }
}

// Run if called directly
if (require.main === module) {
    initializeVault()
        .then((result) => {
            console.log('\n🎉 Vault initialization completed successfully!');
            console.log('Save these addresses for testing:');
            console.log('Vault PDA:', result.vaultPda.toString());
            console.log('Token Vault PDA:', result.tokenVaultPda.toString());
            console.log('Program ID:', result.programId.toString());
            
            // Save to file for later use
            const addresses = {
                vaultPda: result.vaultPda.toString(),
                tokenVaultPda: result.tokenVaultPda.toString(),
                programId: result.programId.toString(),
                qupdevMint: '8bjKA2mkXMdkUHC6m8TfyQcksTDLKeP61XmFFcVViYef'
            };
            fs.writeFileSync('./vault_addresses.json', JSON.stringify(addresses, null, 2));
            console.log('📁 Addresses saved to vault_addresses.json');
        })
        .catch((error) => {
            console.error('Failed to initialize vault:', error);
            process.exit(1);
        });
}

module.exports = { initializeVault };
