const anchor = require("@coral-xyz/anchor");
const { PublicKey } = anchor.web3;
const BN = require('bn.js');

describe("new_qup_staking", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);
  const program = anchor.workspace.NewQupStaking;

  it("Initializes the vault", async () => {
    const vault = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("vault"), new PublicKey("DGC9jBJTMQeWATH6ecnRfBUfjncFfoG1b4VyZXmSxNq9").toBuffer()],
      new PublicKey("BQ71gq1J5oftcqsnQzz1rWgVo4b7PmD8i1x4gy2wDnuu")
    )[0];
    const lpMint = new PublicKey("DGC9jBJTMQeWATH6ecnRfBUfjncFfoG1b4VyZXmSxNq9");
    const [vaultAuthority, bump] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("vault"), lpMint.toBuffer()],
      program.programId
    );
    await program.methods
      .initializeVault(bump, new BN(604800))
      .accounts({
        authority: provider.wallet.publicKey,
        vault: vault,
        lpTokenMint: lpMint,
        rewardMint: new PublicKey("DbnKXgYEy4EeARCZgwu6WR7Y5Y58Ysd1jHpB6pPN3WbE"),
        stakingVault: new PublicKey("HV8rFfkyTi8dbuZj3aFkVwdcUenoHov7WiLnDPFUZRN5"),
        rewardVault: new PublicKey("76hqyncrLzVT8tyakvyL4UbqjRJ9rAt8mJmt6CT9XycZ"),
        vaultAuthority,
        systemProgram: anchor.web3.SystemProgram.programId,
        tokenProgram: anchor.utils.token.TOKEN_PROGRAM_ID,
        rent: anchor.web3.SYSVAR_RENT_PUBKEY,
      })
      .rpc();
  });
});
