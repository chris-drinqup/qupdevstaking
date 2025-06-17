# 🎉 QUP Vault Staking: Lessons Learned
## From Devnet Debugging to Mainnet Success

**Congratulations!** Your staking transaction worked! Here's everything we learned to ensure a smooth transition to mainnet.

---

## 🔧 Critical Issues We Fixed

### 1. **Wrong Instruction Discriminator (MAJOR)**
**Problem:** Frontend was calling `initialize_vault` instead of `stake`
```javascript
// ❌ WRONG (initialize_vault discriminator)
const stakeDiscriminator = new Uint8Array([48, 191, 163, 44, 71, 129, 63, 164]);

// ✅ CORRECT (stake discriminator)  
const stakeDiscriminator = new Uint8Array([206, 176, 202, 18, 200, 209, 179, 108]);
```

**How to Calculate:** SHA-256 hash of `"global:stake"`, first 8 bytes
**Error Signs:** `"Instruction: InitializeVault"` in logs, Error 3010 (AccountNotSigner)

### 2. **Missing Required Accounts**
**Problem:** Anchor program expected `rent` sysvar but it wasn't provided
**Error Signs:** Error 3005 (AccountNotEnoughKeys), `"account: rent"` in error message

### 3. **Wrong Account Order (CRITICAL)**
**Problem:** System Program and Rent Sysvar were in wrong positions
```javascript
// ✅ CORRECT ORDER for your program:
keys: [
    { pubkey: VAULT_CONFIG.vaultPda, isSigner: false, isWritable: true },           // 1. vault
    { pubkey: userStakePda, isSigner: false, isWritable: true },                   // 2. user_stake  
    { pubkey: wallet, isSigner: true, isWritable: true },                          // 3. user
    { pubkey: userTokenAccount, isSigner: false, isWritable: true },               // 4. user_token_account
    { pubkey: VAULT_CONFIG.tokenVaultPda, isSigner: false, isWritable: true },     // 5. token_vault
    { pubkey: new solanaWeb3.PublicKey('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA'), isSigner: false, isWritable: false }, // 6. token_program
    { pubkey: solanaWeb3.SystemProgram.programId, isSigner: false, isWritable: false }, // 7. system_program  
    { pubkey: solanaWeb3.SYSVAR_RENT_PUBKEY, isSigner: false, isWritable: false }       // 8. rent
]
```

**Error Signs:** Error 3008 (InvalidProgramId), logs showing expected vs received account types

---

## 🚀 Mainnet Migration Checklist

### **Step 1: Update Contract Addresses**
```javascript
const MAINNET_VAULT_CONFIG = {
    programId: new solanaWeb3.PublicKey('YOUR_MAINNET_PROGRAM_ID'),
    vaultPda: new solanaWeb3.PublicKey('YOUR_MAINNET_VAULT_PDA'),
    tokenVaultPda: new solanaWeb3.PublicKey('YOUR_MAINNET_TOKEN_VAULT_PDA'),
    qupMint: new solanaWeb3.PublicKey('YOUR_REAL_QUP_MINT_ADDRESS') // Real QUP token
};
```

### **Step 2: Update RPC Endpoint**
```javascript
// Change from devnet to mainnet
connection = new solanaWeb3.Connection('https://api.mainnet-beta.solana.com', 'confirmed');
// Or use a premium RPC like Helius/QuickNode for better reliability
```

### **Step 3: Verify Account Order Match**
- **Test with small amounts first!**
- Use the exact same account order that worked on devnet
- Double-check your Rust program's account structure matches

### **Step 4: Update Token Decimals (If Different)**
```javascript
// Verify your real QUP token decimals
const amountLamports = Math.floor(stakingAmount * Math.pow(10, QUP_DECIMALS));
```

### **Step 5: Remove Test-Specific Code**
- Remove devnet-only testing buttons
- Remove token request email functionality  
- Update UI to show mainnet Explorer links
- Add production error handling

---

## 🧪 Testing Strategy for Mainnet

### **Phase 1: Simulation Testing**
1. Use `skipPreflight: false` initially to catch errors
2. Test with very small amounts (0.01 QUP)
3. Verify all account addresses exist on mainnet

### **Phase 2: Live Testing**
1. Start with minimum stake amount
2. Test full staking workflow
3. Test unstaking/claiming (if implemented)
4. Monitor transaction costs

### **Phase 3: Production Launch**
1. Test with multiple wallets
2. Document gas fees for users
3. Add proper error messages for common issues

---

## 🐛 Common Error Patterns & Solutions

| Error Code | Error Type | Common Cause | Solution |
|------------|------------|--------------|----------|
| 3010 | AccountNotSigner | Wrong discriminator | Verify instruction discriminator calculation |
| 3005 | AccountNotEnoughKeys | Missing accounts | Add all required sysvars (rent, clock, etc.) |
| 3008 | InvalidProgramId | Wrong account order | Match exact order from Rust program |
| 3001 | AccountDiscriminatorMismatch | Wrong account type | Verify PDA derivation matches program |

---

## 💡 Pro Tips for Production

### **Security Best Practices**
- Always validate user inputs
- Set reasonable staking limits  
- Add confirmation dialogs for large amounts
- Use error boundaries in React/frontend

### **User Experience**
- Show clear error messages (not raw error codes)
- Add loading states for all async operations
- Display estimated transaction fees
- Provide transaction history/status

### **Monitoring & Debugging**
- Log all transaction signatures for support
- Monitor failed transactions
- Track most common user errors
- Keep devnet version for testing updates

---

## 🔍 Key Debugging Commands

```bash
# Check account exists on mainnet
solana account YOUR_ACCOUNT_ADDRESS --url mainnet-beta

# Check token balance
spl-token balance YOUR_MINT_ADDRESS --owner YOUR_WALLET --url mainnet-beta

# Verify program deployment
solana account YOUR_PROGRAM_ID --url mainnet-beta

# Get transaction details
solana confirm TRANSACTION_SIGNATURE --url mainnet-beta
```

---

## 🎯 Final Success Formula

**✅ Correct Discriminator** + **✅ Complete Account List** + **✅ Proper Account Order** = **Working Staking!**

The key lesson: **Anchor programs are extremely particular about account order and instruction discriminators.** When you get these exactly right, everything works perfectly.

---

## 📞 Emergency Troubleshooting

If you run into issues on mainnet:

1. **Compare working devnet transaction** with failing mainnet transaction
2. **Check each account address** exists and has correct type  
3. **Verify discriminator calculation** for your mainnet program
4. **Test account order variations** if needed (but unlikely to change)
5. **Use simulation mode** to debug without spending SOL

**Remember:** You conquered devnet debugging - mainnet will be much easier now that you know the patterns! 🚀
