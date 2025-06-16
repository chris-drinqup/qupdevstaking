# Fix the borrowing issues in lib.rs
cat > programs/new_qup_staking/src/lib.rs << 'EOF'
use anchor_lang::prelude::*;
use anchor_spl::token::{self, Token, TokenAccount, Transfer};

declare_id!("11111111111111111111111111111112");

#[program]
pub mod new_qup_staking {
    use super::*;

    pub fn initialize_vault(
        ctx: Context<InitializeVault>,
        bump: u8,
    ) -> Result<()> {
        let vault = &mut ctx.accounts.vault;
        vault.authority = ctx.accounts.authority.key();
        vault.token_mint = ctx.accounts.token_mint.key();
        vault.token_vault = ctx.accounts.token_vault.key();
        vault.total_staked = 0;
        vault.reward_rate = 100; // 1% daily (100 basis points)
        vault.last_update_time = Clock::get()?.unix_timestamp;
        vault.bump = bump;

        msg!("Vault initialized successfully");
        Ok(())
    }

    pub fn stake(ctx: Context<Stake>, amount: u64) -> Result<()> {
        let clock = Clock::get()?;
        
        // Get vault key before mutable borrow
        let vault_key = ctx.accounts.vault.key();
        let vault = &mut ctx.accounts.vault;
        let user_stake = &mut ctx.accounts.user_stake;

        // Update vault rewards before processing stake
        let time_elapsed = clock.unix_timestamp - vault.last_update_time;
        vault.last_update_time = clock.unix_timestamp;

        // Initialize user stake if first time
        if user_stake.amount == 0 {
            user_stake.owner = ctx.accounts.user.key();
            user_stake.vault = vault_key;
            user_stake.last_stake_time = clock.unix_timestamp;
        }

        // Calculate pending rewards before updating stake
        let pending_rewards = calculate_rewards(user_stake.amount, time_elapsed, vault.reward_rate);
        user_stake.pending_rewards += pending_rewards;

        // Transfer tokens from user to vault
        let transfer_instruction = Transfer {
            from: ctx.accounts.user_token_account.to_account_info(),
            to: ctx.accounts.token_vault.to_account_info(),
            authority: ctx.accounts.user.to_account_info(),
        };
        token::transfer(
            CpiContext::new(ctx.accounts.token_program.to_account_info(), transfer_instruction),
            amount,
        )?;

        // Update stake amounts
        user_stake.amount += amount;
        vault.total_staked += amount;
        user_stake.last_stake_time = clock.unix_timestamp;

        msg!("Staked {} tokens successfully", amount);
        Ok(())
    }

    pub fn unstake(ctx: Context<Unstake>, amount: u64) -> Result<()> {
        let clock = Clock::get()?;
        let vault = &mut ctx.accounts.vault;
        let user_stake = &mut ctx.accounts.user_stake;

        require!(user_stake.amount >= amount, ErrorCode::InsufficientStake);

        // Calculate and add pending rewards
        let time_elapsed = clock.unix_timestamp - user_stake.last_stake_time;
        let pending_rewards = calculate_rewards(user_stake.amount, time_elapsed, vault.reward_rate);
        user_stake.pending_rewards += pending_rewards;

        // Create signer seeds for vault authority (get values before using vault)
        let authority_seed = vault.authority.as_ref();
        let bump_seed = &[vault.bump];
        let seeds = &[b"vault".as_ref(), authority_seed, bump_seed];
        let signer_seeds = &[&seeds[..]];

        // Transfer tokens from vault back to user
        let transfer_instruction = Transfer {
            from: ctx.accounts.token_vault.to_account_info(),
            to: ctx.accounts.user_token_account.to_account_info(),
            authority: ctx.accounts.vault.to_account_info(),
        };
        token::transfer(
            CpiContext::new_with_signer(
                ctx.accounts.token_program.to_account_info(),
                transfer_instruction,
                signer_seeds,
            ),
            amount,
        )?;

        // Update stake amounts
        user_stake.amount -= amount;
        vault.total_staked -= amount;
        user_stake.last_stake_time = clock.unix_timestamp;

        msg!("Unstaked {} tokens successfully", amount);
        Ok(())
    }

    pub fn claim_rewards(ctx: Context<ClaimRewards>) -> Result<()> {
        let clock = Clock::get()?;
        let vault = &mut ctx.accounts.vault;
        let user_stake = &mut ctx.accounts.user_stake;

        // Calculate total rewards
        let time_elapsed = clock.unix_timestamp - user_stake.last_stake_time;
        let pending_rewards = calculate_rewards(user_stake.amount, time_elapsed, vault.reward_rate);
        let total_rewards = user_stake.pending_rewards + pending_rewards;

        require!(total_rewards > 0, ErrorCode::NoRewardsAvailable);

        // Create signer seeds for vault authority (get values before using vault)
        let authority_seed = vault.authority.as_ref();
        let bump_seed = &[vault.bump];
        let seeds = &[b"vault".as_ref(), authority_seed, bump_seed];
        let signer_seeds = &[&seeds[..]];

        // Transfer rewards from vault to user
        let transfer_instruction = Transfer {
            from: ctx.accounts.token_vault.to_account_info(),
            to: ctx.accounts.user_token_account.to_account_info(),
            authority: ctx.accounts.vault.to_account_info(),
        };
        token::transfer(
            CpiContext::new_with_signer(
                ctx.accounts.token_program.to_account_info(),
                transfer_instruction,
                signer_seeds,
            ),
            total_rewards,
        )?;

        // Reset rewards and update last stake time
        user_stake.pending_rewards = 0;
        user_stake.last_stake_time = clock.unix_timestamp;

        msg!("Claimed {} tokens in rewards", total_rewards);
        Ok(())
    }
}

// Helper function to calculate rewards
fn calculate_rewards(stake_amount: u64, time_elapsed: i64, reward_rate: u64) -> u64 {
    if stake_amount == 0 || time_elapsed <= 0 {
        return 0;
    }
    
    // Calculate daily rewards: stake_amount * reward_rate / 10000 / seconds_per_day * time_elapsed
    let daily_reward = (stake_amount as u128 * reward_rate as u128) / 10000;
    let seconds_per_day = 86400;
    let total_reward = (daily_reward * time_elapsed as u128) / seconds_per_day;
    
    total_reward as u64
}

#[derive(Accounts)]
#[instruction(bump: u8)]
pub struct InitializeVault<'info> {
    #[account(
        init,
        payer = authority,
        space = 8 + 32 + 32 + 32 + 8 + 8 + 8 + 1,
        seeds = [b"vault", authority.key().as_ref()],
        bump
    )]
    pub vault: Account<'info, Vault>,
    
    #[account(mut)]
    pub authority: Signer<'info>,
    
    pub token_mint: Account<'info, anchor_spl::token::Mint>,
    
    #[account(
        init,
        payer = authority,
        token::mint = token_mint,
        token::authority = vault,
        seeds = [b"token_vault", authority.key().as_ref()],
        bump
    )]
    pub token_vault: Account<'info, TokenAccount>,
    
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
    pub rent: Sysvar<'info, Rent>,
}

#[derive(Accounts)]
pub struct Stake<'info> {
    #[account(mut)]
    pub vault: Account<'info, Vault>,
    
    #[account(
        init_if_needed,
        payer = user,
        space = 8 + 32 + 32 + 8 + 8 + 8,
        seeds = [b"user_stake", user.key().as_ref(), vault.key().as_ref()],
        bump
    )]
    pub user_stake: Account<'info, UserStake>,
    
    #[account(mut)]
    pub user: Signer<'info>,
    
    #[account(
        mut,
        constraint = user_token_account.owner == user.key(),
        constraint = user_token_account.mint == vault.token_mint
    )]
    pub user_token_account: Account<'info, TokenAccount>,
    
    #[account(
        mut,
        constraint = token_vault.key() == vault.token_vault
    )]
    pub token_vault: Account<'info, TokenAccount>,
    
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
    pub rent: Sysvar<'info, Rent>,
}

#[derive(Accounts)]
pub struct Unstake<'info> {
    #[account(mut)]
    pub vault: Account<'info, Vault>,
    
    #[account(
        mut,
        seeds = [b"user_stake", user.key().as_ref(), vault.key().as_ref()],
        bump,
        constraint = user_stake.owner == user.key()
    )]
    pub user_stake: Account<'info, UserStake>,
    
    #[account(mut)]
    pub user: Signer<'info>,
    
    #[account(
        mut,
        constraint = user_token_account.owner == user.key(),
        constraint = user_token_account.mint == vault.token_mint
    )]
    pub user_token_account: Account<'info, TokenAccount>,
    
    #[account(
        mut,
        constraint = token_vault.key() == vault.token_vault
    )]
    pub token_vault: Account<'info, TokenAccount>,
    
    pub token_program: Program<'info, Token>,
}

#[derive(Accounts)]
pub struct ClaimRewards<'info> {
    #[account(mut)]
    pub vault: Account<'info, Vault>,
    
    #[account(
        mut,
        seeds = [b"user_stake", user.key().as_ref(), vault.key().as_ref()],
        bump,
        constraint = user_stake.owner == user.key()
    )]
    pub user_stake: Account<'info, UserStake>,
    
    #[account(mut)]
    pub user: Signer<'info>,
    
    #[account(
        mut,
        constraint = user_token_account.owner == user.key(),
        constraint = user_token_account.mint == vault.token_mint
    )]
    pub user_token_account: Account<'info, TokenAccount>,
    
    #[account(
        mut,
        constraint = token_vault.key() == vault.token_vault
    )]
    pub token_vault: Account<'info, TokenAccount>,
    
    pub token_program: Program<'info, Token>,
}

#[account]
pub struct Vault {
    pub authority: Pubkey,
    pub token_mint: Pubkey,
    pub token_vault: Pubkey,
    pub total_staked: u64,
    pub reward_rate: u64, // basis points per day
    pub last_update_time: i64,
    pub bump: u8,
}

#[account]
pub struct UserStake {
    pub owner: Pubkey,
    pub vault: Pubkey,
    pub amount: u64,
    pub pending_rewards: u64,
    pub last_stake_time: i64,
}

#[error_code]
pub enum ErrorCode {
    #[msg("Insufficient stake amount")]
    InsufficientStake,
    #[msg("No rewards available to claim")]
    NoRewardsAvailable,
}
EOF

echo "✅ Fixed borrowing issues - ready to build!"
