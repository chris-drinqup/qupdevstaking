const anchor = require('@coral-xyz/anchor');
const { PublicKey, Keypair, Connection, SystemProgram } = anchor.web3;
const { TOKEN_PROGRAM_ID } = require('@solana/spl-token');
const fs = require('fs');
const BN = require('bn.js');

// Configuration
const PROGRAM_ID = "BQ71gq1J5oftcqsnQzz1rWgVo4b7PmD8i1x4gy2wDnuu";
const LP_MINT = "DGC9jBJTMQeWATH6ecnRfBUfjncFfoG1b4VyZXmSxNq9";
const REWARD_MINT = "DbnKXgYEy4EeARCZgwu6WR7Y5Y58Ysd1jHpB6pPN3WbE";
const REWARD_VAULT = "76hqyncrLzVT8tyakvyL4UbqjRJ9rAt8mJmt6CT9XycZ";
const STAKING_VAULT = "HV8rFfkyTi8dbuZj3aFkVwdcUenoHov7WiLnDPFUZRN5";
const DURATION_SECONDS = 604800;
const VAULT_PUBKEY = "PDA:"; // Will be replaced dynamically

// Load the actual IDL
const idl = require('/home/chris/krakenbot/pro/questakingpool/new_qup_staking/actual_idl.json');

// Log verbose information for debugging
const DEBUG = true;

async function main() {
  try {
    console.log("==== Initializing QUP LP Staking Vault with Anchor Client ====");
    console.log("Program ID:", PROGRAM_ID);
    console.log("LP Mint:", LP_MINT);
    console.log("Reward Mint:", REWARD_MINT);
    console.log("Staking Vault:", STAKING_VAULT);
    console.log("Reward Vault:", REWARD_VAULT);
    console.log("Expected Vault PDA:", VAULT_PUBKEY);
    console.log("Duration (seconds):", DURATION_SECONDS);
    
    // Load wallet
    const walletPath = process.env.HOME + '/.config/solana/devnet-user.json';
    console.log(`Loading wallet from: ${walletPath}`);
    
    if (!fs.existsSync(walletPath)) {
      throw new Error(`Wallet file not found at ${walletPath}`);
    }
    
    const walletKey = JSON.parse(fs.readFileSync(walletPath, 'utf8'));
    const walletKeyPair = Keypair.fromSecretKey(new Uint8Array(walletKey));
    const wallet = new anchor.Wallet(walletKeyPair);
    console.log(`Wallet public key: ${wallet.publicKey.toString()}`);

    // Set up Anchor provider
    const connection = new Connection('https://api.devnet.solana.com', 'confirmed');
    const provider = new anchor.AnchorProvider(
      connection, 
      wallet, 
      { commitment: 'confirmed' }
    );
    
    anchor.setProvider(provider);
    
    // Check wallet balance
    const balance = await connection.getBalance(wallet.publicKey);
    console.log(`Wallet balance: ${balance / 1e9} SOL`);
    
    if (balance < 10000000) { // 0.01 SOL
      throw new Error("Insufficient wallet balance (< 0.01 SOL)");
    }
    
    // Calculate vault PDA and bump
    const [vaultPDA, bump] = await PublicKey.findProgramAddress(
      [Buffer.from("vault"), new PublicKey(LP_MINT).toBuffer()],
      new PublicKey(PROGRAM_ID)
    );
    
    console.log(`Calculated vault PDA: ${vaultPDA.toString()} (bump: ${bump})`);
    
    if (vaultPDA.toString() !== VAULT_PUBKEY) {
      throw new Error(`Calculated PDA ${vaultPDA.toString()} doesn't match expected vault address ${VAULT_PUBKEY}`);
    }
    
    // Check if vault already exists
    const vaultAccount = await connection.getAccountInfo(vaultPDA);
    if (vaultAccount !== null) {
      console.log(`Vault account already exists with owner: ${vaultAccount.owner.toString()}`);
      console.log(`Data length: ${vaultAccount.data.length} bytes`);
      return;
    }
    
    console.log("Vault account does not exist, proceeding with initialization...");
    
    // Create program interface with IDL
    const program = new anchor.Program(idl, new PublicKey(PROGRAM_ID), provider);
    
    // Log available methods from the IDL
    console.log("Available methods in IDL:", Object.keys(program.methods));
    
    // Use the method name from the IDL
    const methodName = "initializeVault";
    if (!program.methods[methodName]) {
      console.error(`Method "${methodName}" not found in IDL. Available methods: ${Object.keys(program.methods)}`);
      process.exit(1);
    }
    
    // Log the instruction we're about to send
    if (DEBUG) {
      console.log("Instruction details:", {
        name: methodName,
        accounts: {
          authority: wallet.publicKey.toString(),
          vault: vaultPDA.toString(),
          lpTokenMint: LP_MINT,
          rewardMint: REWARD_MINT,
          stakingVault: STAKING_VAULT,
          rewardVault: REWARD_VAULT,
          vaultAuthority: vaultPDA.toString(),
          systemProgram: SystemProgram.programId.toString(),
          tokenProgram: TOKEN_PROGRAM_ID.toString(),
          rent: anchor.web3.SYSVAR_RENT_PUBKEY.toString()
        },
        args: { bump: bump, duration: DURATION_SECONDS }
      });
    }
    
    console.log(`Initializing vault with Anchor client using instruction '${methodName}'...`);
    
    const tx = await program.methods[methodName](bump, new BN(DURATION_SECONDS))
      .accounts({
        authority: wallet.publicKey,
        vault: vaultPDA,
        lpTokenMint: new PublicKey(LP_MINT),
        rewardMint: new PublicKey(REWARD_MINT),
        stakingVault: new PublicKey(STAKING_VAULT),
        rewardVault: new PublicKey(REWARD_VAULT),
        vaultAuthority: vaultPDA,
        systemProgram: SystemProgram.programId,
        tokenProgram: TOKEN_PROGRAM_ID,
        rent: anchor.web3.SYSVAR_RENT_PUBKEY
      })
      .signers([walletKeyPair])
      .rpc();
    
    console.log("✅ Vault initialized successfully!");
    console.log("Transaction signature:", tx);
    console.log("Transaction URL: https://explorer.solana.com/tx/" + tx + "?cluster=devnet");
    
    // Verify the vault account was created
    console.log("Verifying vault account creation...");
    const newVaultAccount = await connection.getAccountInfo(vaultPDA);
    if (newVaultAccount === null) {
      throw new Error("Vault account not found after initialization");
    }
    
    console.log(`Vault account created with size: ${newVaultAccount.data.length} bytes`);
    console.log(`Vault owner: ${newVaultAccount.owner.toString()}`);
    
    if (newVaultAccount.owner.toString() === PROGRAM_ID) {
      console.log("Owner validation successful: Vault is owned by the program ✅");
    } else {
      console.error(`Owner validation failed: Expected ${PROGRAM_ID}, got ${newVaultAccount.owner.toString()}`);
    }
  } catch (error) {
    console.error("❌ Error:", error.message);
    if (error.logs) {
      console.error("Transaction logs:", error.logs);
    }
    throw error;
  }
}

main();
