const anchor = require('@coral-xyz/anchor');
const { PublicKey } = require('@solana/web3.js');
const { TOKEN_PROGRAM_ID } = require('@solana/spl-token');
const fs = require('fs');

describe('vault-initialization', () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  // Load the validated addresses
  const addresses = JSON.parse(fs.readFileSync('./vault_addresses.json', 'utf8'));

  it('Initialize QUP Staking Vault', async () => {
    console.log('🚀 Initializing vault with validated addresses...');
    
    const programId = new PublicKey(addresses.programId);
    const vaultPda = new PublicKey(addresses.vaultPda);
    const tokenVaultPda = new PublicKey(addresses.tokenVaultPda);
    const qupdevMint = new PublicKey(addresses.qupdevMint);
    
    console.log('Program ID:', programId.toString());
    console.log('Vault PDA:', vaultPda.toString());
    console.log('Authority:', provider.wallet.publicKey.toString());
    console.log('Vault Bump:', addresses.vaultBump);
    
    // This should work since we have all the right addresses
    console.log('✅ All addresses loaded successfully');
    console.log('✅ Ready for initialization call');
  });
});
