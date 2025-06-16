#!/bin/bash

# Script to create, build, deploy, and initialize a QUP LP Staking Vault on Devnet
# Lessons learned:
# - Use -- --verbose for anchor build to avoid invalid flag error
# - Lock lib.rs and Anchor.toml to prevent PROGRAM_ID mismatch
# - Use Rust 1.87.0 consistently for lock file generation to avoid version 4 lock file issues
# - Ensure valid Cargo.toml with anchor-lang version to avoid manifest parsing errors
# - Use manual build (cargo build-sbf) to bypass avm errors
# - Fix anchor_version in Anchor.toml to avoid version mismatches
# - Nightly toolchain (e.g., 1.89.0-nightly) may not support version 4 lock files; manually set to version 3
# - Dependency conflicts (e.g., solana-address-lookup-table-interface, solana-atomic-u64) can prevent building
# - Use transaction simulation to debug issues (e.g., InstructionFallbackNotFound) without consuming SOL
# - Generate a new keypair for the program to ensure a unique program ID
# - Update Anchor.toml and lib.rs with the new program ID before building
# - Deploy the program with the correct keypair to ensure the IDL is uploaded
# - Force Cargo.lock to use version 3 to avoid lock file version mismatches
# - Specify the correct library path in Cargo.toml for Anchor programs (path = "programs/<program_name>/src/lib.rs")
# - Ensure heredoc sections (e.g., << EOL) are properly closed with no trailing whitespace
# - Use the correct program name inside programs/ directory (e.g., new_qup_staking)
# - Validate project structure before proceeding to avoid missing directories
# - Use the correct project directory (e.g., new_qup_staking) to avoid rename confusion
# - If all approaches fail, disassemble the program or check the source code for the correct instruction name

set -e

# Configuration
LP_MINT="DGC9jBJTMQeWATH6ecnRfBUfjncFfoG1b4VyZXmSxNq9"
REWARD_MINT="DbnKXgYEy4EeARCZgwu6WR7Y5Y58Ysd1jHpB6pPN3WbE"
REWARD_VAULT="76hqyncrLzVT8tyakvyL4UbqjRJ9rAt8mJmt6CT9XycZ"
STAKING_VAULT="HV8rFfkyTi8dbuZj3aFkVwdcUenoHov7WiLnDPFUZRN5"
DURATION_SECONDS=604800
PROJECT_DIR="$HOME/krakenbot/pro/questakingpool/new_qup_staking"
DEPLOY_DIR="$HOME/krakenbot/pro/questakingpool/new_qup_staking/vault_package"
SUMMARY_FILE="$DEPLOY_DIR/qup_vault_build_summary.txt"
FETCH_LOG="$DEPLOY_DIR/git_fetch.log"
IDL_DIR="$PROJECT_DIR/target/idl"
ANCHOR_VERSION="0.31.1"
KEYPAIR_FILE="$PROJECT_DIR/keypairs/new_qup_staking.json"
IDL_FILE="$PROJECT_DIR/actual_idl.json"
PROGRAM_NAME="new_qup_staking"

# Function to log messages
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$SUMMARY_FILE"
}

# Function to check command existence
check_command() {
  if ! command -v "$1" &> /dev/null; then
    log "Error: $1 not found"
    return 1
  fi
  return 0
}

# Function to validate program ID strictly
validate_program_id() {
  local dir="$1"
  local prog_id="$2"
  log "Validating program ID in lib.rs and Anchor.toml in $dir..."
  if ! grep -q "declare_id!(\"$prog_id\")" "$dir/programs/$PROGRAM_NAME/src/lib.rs" 2>/dev/null; then
    log "Error: lib.rs does not contain expected program ID $prog_id"
    exit 1
  fi
  if ! grep -q "$PROGRAM_NAME = \"$prog_id\"" "$dir/Anchor.toml" 2>/dev/null; then
    log "Error: Anchor.toml does not contain expected program ID $prog_id"
    exit 1
  fi
}

# Function to validate project structure
validate_project_structure() {
  local dir="$1"
  log "Validating project structure in $dir..."
  if [ ! -d "$dir/programs/$PROGRAM_NAME" ]; then
    log "Error: Program directory $dir/programs/$PROGRAM_NAME does not exist"
    exit 1
  fi
  if [ ! -f "$dir/programs/$PROGRAM_NAME/src/lib.rs" ]; then
    log "Error: lib.rs not found at $dir/programs/$PROGRAM_NAME/src/lib.rs"
    exit 1
  fi
  if [ ! -f "$dir/Anchor.toml" ]; then
    log "Error: Anchor.toml not found at $dir/Anchor.toml"
    exit 1
  fi
  if [ ! -f "$dir/Cargo.toml" ]; then
    log "Error: Cargo.toml not found at $dir/Cargo.toml"
    exit 1
  fi
}

# Initialize summary file
mkdir -p "$DEPLOY_DIR"
echo "QUP_LP_Staking_Vault Build and Initialize Summary" > "$SUMMARY_FILE"
echo "Generated on: $(date)" >> "$SUMMARY_FILE"
echo "----------------------------------------" >> "$SUMMARY_FILE"

# Step 1: Verify Anchor CLI installation
if ! check_command anchor || ! anchor --version | grep -q "0.31.1"; then
  log "Installing Anchor CLI 0.31.1..."
  cargo +1.87.0 uninstall anchor-cli || true
  cargo +1.87.0 install --git https://github.com/coral-xyz/anchor --tag v0.31.1 anchor-cli --locked --force
fi
ANCHOR_VERSION=$(anchor --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
if [[ "$ANCHOR_VERSION" != "0.31.1" ]]; then
  log "Error: Anchor version is $ANCHOR_VERSION, expected 0.31.1"
  exit 1
fi

# Step 2: Check if the project directory exists; if not, create it
if [ -d "$PROJECT_DIR" ]; then
  log "Project directory $PROJECT_DIR exists. Using existing project..."
  validate_project_structure "$PROJECT_DIR"
else
  log "Creating a new Anchor project for $PROGRAM_NAME..."
  cd "$(dirname "$PROJECT_DIR")"
  anchor init "$PROGRAM_NAME"
  cd "$PROGRAM_NAME"
  PROJECT_DIR="$(pwd)"
  DEPLOY_DIR="$PROJECT_DIR/vault_package"
  SUMMARY_FILE="$DEPLOY_DIR/qup_vault_build_summary.txt"
  FETCH_LOG="$DEPLOY_DIR/git_fetch.log"
  IDL_DIR="$PROJECT_DIR/target/idl"
  KEYPAIR_FILE="$PROJECT_DIR/keypairs/new_qup_staking.json"
  IDL_FILE="$PROJECT_DIR/actual_idl.json"
fi

# Step 3: Generate a new keypair for the program if it doesn't exist
if [ ! -f "$KEYPAIR_FILE" ]; then
  log "Generating a new keypair for the program..."
  mkdir -p "$PROJECT_DIR/keypairs"
  solana-keygen new --no-bip39-passphrase --outfile "$KEYPAIR_FILE" 2>&1 | tee -a "$SUMMARY_FILE"
fi
PROGRAM_ID=$(solana-keygen pubkey "$KEYPAIR_FILE")
log "Program ID: $PROGRAM_ID"

# Step 4: Update Anchor.toml with the program ID
log "Updating Anchor.toml with the program ID..."
cat > "$PROJECT_DIR/Anchor.toml" << EOL
[programs.devnet]
$PROGRAM_NAME = "$PROGRAM_ID"

[provider]
cluster = "devnet"
wallet = "~/.config/solana/devnet-user.json"
EOL

# Step 5: Update lib.rs with the program ID and vault logic
log "Updating lib.rs with the program ID and vault logic..."
cat > "$PROJECT_DIR/programs/$PROGRAM_NAME/src/lib.rs" << EOL
use anchor_lang::prelude::*;
use anchor_spl::token::{Token, TokenAccount};

declare_id!("$PROGRAM_ID");

#[program]
pub mod $PROGRAM_NAME {
    use super::*;

    pub fn initialize_vault(
        ctx: Context<InitializeVault>,
        bump: u8,
        duration: u64,
    ) -> Result<()> {
        let vault = &mut ctx.accounts.vault;
        vault.authority = *ctx.accounts.authority.key;
        vault.lp_token_mint = *ctx.accounts.lp_token_mint.key;
        vault.reward_mint = *ctx.accounts.reward_mint.key;
        vault.staking_vault = *ctx.accounts.staking_vault.key;
        vault.reward_vault = *ctx.accounts.reward_vault.key;
        vault.duration = duration;
        vault.bump = bump;
        Ok(())
    }
}

#[derive(Accounts)]
#[instruction(bump: u8)]
pub struct InitializeVault<'info> {
    #[account(mut)]
    pub authority: Signer<'info>,
    #[account(
        init,
        payer = authority,
        space = 8 + 32 + 32 + 32 + 32 + 32 + 8 + 1,
        seeds = [b"vault", lp_token_mint.key().as_ref()],
        bump
    )]
    pub vault: Account<'info, Vault>,
    pub lp_token_mint: AccountInfo<'info>,
    pub reward_mint: AccountInfo<'info>,
    #[account(mut)]
    pub staking_vault: Account<'info, TokenAccount>,
    #[account(mut)]
    pub reward_vault: Account<'info, TokenAccount>,
    #[account(seeds = [b"vault", lp_token_mint.key().as_ref()], bump)]
    pub vault_authority: AccountInfo<'info>,
    pub system_program: Program<'info, System>,
    pub token_program: Program<'info, Token>,
    pub rent: Sysvar<'info, Rent>,
}

#[account]
pub struct Vault {
    pub authority: Pubkey,
    pub lp_token_mint: Pubkey,
    pub reward_mint: Pubkey,
    pub staking_vault: Pubkey,
    pub reward_vault: Pubkey,
    pub duration: u64,
    pub bump: u8,
}
EOL

# Step 6: Build the program
log "Attempting to build the program..."
cd "$PROJECT_DIR"
set +e
(
  set -e
  log "Updating Cargo.toml to avoid dependency conflicts and specify library path..."
  cat > Cargo.toml << EOL
[package]
name = "new_qup_staking"
version = "0.1.0"
description = "Created with Anchor"
edition = "2021"

[lib]
name = "$PROGRAM_NAME"
crate-type = ["cdylib", "lib"]
path = "programs/$PROGRAM_NAME/src/lib.rs"

[features]
default = []

[dependencies]
anchor-lang = "0.31.1"
anchor-spl = { version = "0.31.1", features = ["no-entrypoint"] }
solana-program = "=2.0.0"

[dev-dependencies]
mocha = "0.1"
EOL

  log "Generating lockfile with Rust nightly..."
  rm -f Cargo.lock
  export RUSTUP_TOOLCHAIN=nightly
  cargo +nightly generate-lockfile
  sed -i 's/version = 4/version = 3/' Cargo.lock

  log "Verifying Cargo.lock version..."
  LOCKFILE_VERSION=$(grep -E '^version = [0-9]+' Cargo.lock | head -1 | grep -o '[0-9]\+' || echo "unknown")
  log "Cargo.lock version: $LOCKFILE_VERSION"
  if [[ "$LOCKFILE_VERSION" == "unknown" ]]; then
    log "Error: Could not determine Cargo.lock version. Please generate Cargo.lock with a compatible version."
    exit 1
  fi
  if [[ "$LOCKFILE_VERSION" -ge 4 ]]; then
    log "Error: Cargo.lock version $LOCKFILE_VERSION is incompatible with this version of Cargo (nightly 2025-05-14)."
    log "Please manually set the version to 3 in Cargo.lock and try again."
    exit 1
  fi

  log "Building with anchor..."
  anchor build
)
BUILD_SUCCESS=$?
set -e

if [ $BUILD_SUCCESS -eq 0 ]; then
  log "Build succeeded. Proceeding with deployment..."
else
  log "Build failed. Please check the logs and resolve dependency conflicts."
  exit 1
fi

# Step 7: Deploy the program
log "Deploying the program to Devnet..."
anchor deploy --provider.cluster devnet --program-keypair "$KEYPAIR_FILE" 2>&1 | tee -a "$SUMMARY_FILE"

# Step 8: Fetch the IDL
log "Fetching the IDL for the deployed program..."
anchor idl fetch "$PROGRAM_ID" --provider.cluster devnet > "$IDL_FILE" 2>&1 | tee -a "$SUMMARY_FILE"
if [ ! -f "$IDL_FILE" ]; then
  log "❌ Failed to fetch IDL. Please check the deployment logs."
  exit 1
fi

# Step 9: Compute the new vault PDA
log "Computing the new vault PDA..."
mkdir -p "$DEPLOY_DIR"
cat > "$DEPLOY_DIR/compute_pda.js" << 'EOL'
const { PublicKey } = require('@solana/web3.js');

async function computeVaultPDA() {
  const [vaultPDA, bump] = await PublicKey.findProgramAddress(
    [Buffer.from("vault"), new PublicKey("DGC9jBJTMQeWATH6ecnRfBUfjncFfoG1b4VyZXmSxNq9").toBuffer()],
    new PublicKey("BQ71gq1J5oftcqsnQzz1rWgVo4b7PmD8i1x4gy2wDnuu")
  );
  console.log("New Vault PDA:", vaultPDA.toString(), "Bump:", bump);
}

computeVaultPDA();
EOL

cd "$DEPLOY_DIR"
npm install @solana/web3.js@1.95.3 2>&1 | tee -a "$SUMMARY_FILE"
VAULT_PDA=$(node compute_pda.js | grep "New Vault PDA:" | awk '{print $3}')
VAULT_BUMP=$(node compute_pda.js | grep "Bump:" | awk '{print $2}')
log "Computed Vault PDA: $VAULT_PDA (Bump: $VAULT_BUMP)"

# Step 10: Initialize the vault using Anchor client
log "Initializing the new vault using Anchor client..."
set +e
(
  set -e
  log "Creating or updating package.json for Anchor dependencies..."
  cat > "$DEPLOY_DIR/package.json" << 'EOL'
{
  "name": "vault-initialize",
  "version": "1.0.0",
  "description": "Initialize QUP LP Staking Vault",
  "main": "anchor_init.js",
  "dependencies": {
    "@coral-xyz/anchor": "0.31.1",
    "@solana/web3.js": "1.95.3",
    "@solana/spl-token": "0.4.8",
    "bn.js": "5.2.1"
  }
}
EOL

  log "Creating Anchor initialization script..."
  cat > "$DEPLOY_DIR/anchor_init.js" << 'EOL'
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
const VAULT_PUBKEY = "$VAULT_PDA";

// Load the actual IDL
const idl = require('$PROJECT_DIR/actual_idl.json');

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
    const [vaultPDA, bump] = await PublicKey.findProgramAddressSync(
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
EOL

  log "Installing or updating required packages for Anchor client..."
  cd "$DEPLOY_DIR"
  npm install 2>&1 | tee -a "$SUMMARY_FILE"

  log "Running Anchor client initialization script..."
  NODE_OUTPUT=$(node anchor_init.js 2>&1 | tee "$DEPLOY_DIR/anchor_init.log" || echo "Anchor init script failed")
  echo "Anchor Init Script Output:" >> "$SUMMARY_FILE"
  echo "$NODE_OUTPUT" >> "$SUMMARY_FILE"
)
ANCHOR_INIT_SUCCESS=$?
set -e

if [ $ANCHOR_INIT_SUCCESS -eq 0 ]; then
  log "Anchor client initialization succeeded."
else
  log "Anchor client initialization failed. Please check the logs for more details."
  exit 1
fi

# Step 11: Validate the deployment and vault
log "Checking program and vault..."
PROGRAM_INFO=$(solana program show "$PROGRAM_ID" --url https://api.devnet.solana.com || echo "Program not found")
echo "Program Info:" >> "$SUMMARY_FILE"
echo "$PROGRAM_INFO" >> "$SUMMARY_FILE"

VAULT_ADDRESS=$(grep "Computed Vault PDA:" "$SUMMARY_FILE" | tail -1 | awk '{print $3}' || echo "$VAULT_PDA")
if [[ -n "$VAULT_ADDRESS" ]]; then
  VAULT_INFO=$(solana account "$VAULT_ADDRESS" --url https://api.devnet.solana.com || echo "Vault not found")
  echo "Vault Info:" >> "$SUMMARY_FILE"
  echo "$VAULT_INFO" >> "$SUMMARY_FILE"
fi

log "Build and initialization complete. Summary written to $SUMMARY_FILE"
echo "----------------------------------------" >> "$SUMMARY_FILE"
echo "Script completed at $(date)" >> "$SUMMARY_FILE"
cat "$SUMMARY_FILE"
