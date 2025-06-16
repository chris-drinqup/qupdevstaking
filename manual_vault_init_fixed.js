const { 
  Connection, 
  PublicKey, 
  Keypair, 
  Transaction, 
  TransactionInstruction,
  SystemProgram,
  SYSVAR_RENT_PUBKEY
} = require('@solana/web3.js');
const { TOKEN_PROGRAM_ID } = require('@solana/spl-token');
const fs = require('fs');
const crypto = require('crypto');

function getInstructionDiscriminator(name) {
    const preimage = `global:${name}`;
    const hash = crypto.createHash('sha256').update(preimage).digest();
    return hash.slice(0, 8);
}

async function manualVaultInitFixed() {
  try {
    // Load validated addresses
    const addresses = JSON.parse(fs.readFileSync('./vault_addresses.json', 'utf8'));
    console.log('📁 Using validated addresses for manual initialization');

    // Connect to devnet
    const connection = new Connection('https://api.devnet.solana.com', 'confirmed');

    // Load wallet
    const walletPath = process.env.ANCHOR_WALLET || '~/.config/solana/id.json';
    const expandedPath = walletPath.replace('~', require('os').homedir());
    const walletKeypair = Keypair.fromSecretKey(
      new Uint8Array(JSON.parse(fs.readFileSync(expandedPath, 'utf8')))
    );

    console.log('🚀 Manual vault initialization starting...');
    console.log('Wallet:', walletKeypair.publicKey.toString());

    // Convert addresses to PublicKey objects
    const programId = new PublicKey(addresses.programId);
    const vaultPda = new PublicKey(addresses.vaultPda);
    const tokenVaultPda = new PublicKey(addresses.tokenVaultPda);
    const qupdevMint = new PublicKey(addresses.qupdevMint);
    const authority = walletKeypair.publicKey;

    // Calculate the CORRECT discriminator for initialize_vault
    const discriminator = getInstructionDiscriminator('initialize_vault');
    console.log('✅ Calculated discriminator:', Array.from(discriminator));
    
    // Build instruction data: [discriminator(8), bump(1)]
    const bumpBuffer = Buffer.from([addresses.vaultBump]);
    const instructionData = Buffer.concat([discriminator, bumpBuffer]);

    console.log('📝 Instruction data length:', instructionData.length);

    // Create the instruction
    const initializeVaultIx = new TransactionInstruction({
      keys: [
        { pubkey: vaultPda, isSigner: false, isWritable: true },           // vault
        { pubkey: authority, isSigner: true, isWritable: true },           // authority  
        { pubkey: qupdevMint, isSigner: false, isWritable: false },        // token_mint
        { pubkey: tokenVaultPda, isSigner: false, isWritable: true },      // token_vault
        { pubkey: TOKEN_PROGRAM_ID, isSigner: false, isWritable: false },  // token_program
        { pubkey: SystemProgram.programId, isSigner: false, isWritable: false }, // system_program
        { pubkey: SYSVAR_RENT_PUBKEY, isSigner: false, isWritable: false } // rent
      ],
      programId: programId,
      data: instructionData
    });

    // Create transaction
    const transaction = new Transaction().add(initializeVaultIx);

    // Get recent blockhash
    const { blockhash } = await connection.getLatestBlockhash();
    transaction.recentBlockhash = blockhash;
    transaction.feePayer = authority;

    console.log('📝 Transaction created with:');
    console.log('- Program ID:', programId.toString());
    console.log('- Vault PDA:', vaultPda.toString());
    console.log('- Token Vault PDA:', tokenVaultPda.toString());
    console.log('- Authority:', authority.toString());
    console.log('- Bump:', addresses.vaultBump);
    console.log('- Discriminator:', Array.from(discriminator));

    // Simulate first to check for errors
    console.log('🧪 Simulating transaction...');
    const simulation = await connection.simulateTransaction(transaction);
    
    if (simulation.value.err) {
      console.error('❌ Simulation failed:', simulation.value.err);
      console.error('Logs:', simulation.value.logs);
      return { success: false, error: 'Simulation failed' };
    }
    
    console.log('✅ Simulation successful!');

    // Sign and send transaction
    console.log('🔐 Signing transaction...');
    transaction.sign(walletKeypair);

    console.log('📡 Sending transaction...');
    const signature = await connection.sendRawTransaction(transaction.serialize());
    
    console.log('⏳ Confirming transaction...');
    await connection.confirmTransaction({
      signature: signature,
      blockhash: blockhash,
      lastValidBlockHeight: (await connection.getLatestBlockhash()).lastValidBlockHeight
    });

    console.log('✅ VAULT INITIALIZED SUCCESSFULLY!');
    console.log('Transaction signature:', signature);
    console.log('Vault PDA:', vaultPda.toString());
    console.log('Token Vault PDA:', tokenVaultPda.toString());

    // Verify the vault was created
    console.log('🔍 Verifying vault creation...');
    const vaultAccount = await connection.getAccountInfo(vaultPda);
    if (vaultAccount) {
      console.log('✅ Vault account created successfully!');
      console.log('- Owner:', vaultAccount.owner.toString());
      console.log('- Data length:', vaultAccount.data.length);
      console.log('- Lamports:', vaultAccount.lamports);
    }

    // Update status in our addresses file
    addresses.status = 'initialized';
    addresses.initializationTx = signature;
    fs.writeFileSync('./vault_addresses.json', JSON.stringify(addresses, null, 2));

    return {
      success: true,
      signature: signature,
      vaultPda: vaultPda.toString(),
      tokenVaultPda: tokenVaultPda.toString()
    };

  } catch (error) {
    console.error('❌ Manual initialization failed:', error);
    if (error.logs) {
      console.error('Transaction logs:', error.logs);
    }
    return { success: false, error: error.message };
  }
}

// Run manual initialization
manualVaultInitFixed()
  .then((result) => {
    if (result.success) {
      console.log('\n🎉 VAULT INITIALIZATION COMPLETED!');
      console.log('Your QUP staking vault is now live on devnet!');
      console.log('Transaction:', result.signature);
      console.log('\n🚀 Ready for community testing!');
    } else {
      console.error('Initialization failed:', result.error);
    }
  })
  .catch(console.error);
