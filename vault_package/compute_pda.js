const { PublicKey } = require('@solana/web3.js');

async function computeVaultPDA() {
  const programId = new PublicKey("BQ71gq1J5oftcqsnQzz1rWgVo4b7PmD8i1x4gy2wDnuu");
  const lpMint = new PublicKey("DGC9jBJTMQeWATH6ecnRfBUfjncFfoG1b4VyZXmSxNq9");
  
  const [vaultPDA, bump] = await PublicKey.findProgramAddress(
    [Buffer.from("vault"), lpMint.toBuffer()],
    programId
  );
  
  console.log("New Vault PDA:", vaultPDA.toString(), "Bump:", bump);
  return { pda: vaultPDA.toString(), bump };
}

computeVaultPDA().then(console.log).catch(console.error);
