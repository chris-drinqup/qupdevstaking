#!/bin/bash

# QUP Vault Test Token Batch Distribution Script - Enhanced Version
# Usage: ./distribute_tokens.sh ADDRESS1 ADDRESS2 ADDRESS3 ...
# Or:    ./distribute_tokens.sh ADDRESS1
# Or:    ./distribute_tokens.sh  (interactive mode)

set -e  # Exit on any error

echo "🎯 QUP Vault Test Token Distribution - Enhanced"
echo "=============================================="

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're on devnet
CURRENT_CLUSTER=$(solana config get | grep "RPC URL" | awk '{print $3}')
if [[ "$CURRENT_CLUSTER" != "https://api.devnet.solana.com" ]]; then
    echo -e "${RED}❌ ERROR: Not on devnet! Current cluster: $CURRENT_CLUSTER${NC}"
    echo "Run: solana config set --url devnet"
    exit 1
fi

echo -e "${GREEN}✅ Confirmed on devnet${NC}"

# Token constants
QUPDEV_MINT="8bjKA2mkXMdkUHC6m8TfyQcksTDLKeP61XmFFcVViYef"
SOL_AMOUNT="0.15"  # Increased from 0.1 for better safety margin
TOKEN_AMOUNT="1000"
VAULT_URL="https://chris-drinqup.github.io/qupdevstaking"

# Function to validate wallet address
validate_address() {
    local address=$1
    if [[ ${#address} -ne 44 ]]; then
        echo -e "${RED}❌ Invalid wallet address: $address (should be 44 characters)${NC}"
        return 1
    fi
    if [[ ! "$address" =~ ^[A-Za-z0-9]+$ ]]; then
        echo -e "${RED}❌ Invalid wallet address format: $address${NC}"
        return 1
    fi
    
    # Additional validation - check if it looks like a valid Solana address
    if [[ "$address" =~ ^[1-9A-HJ-NP-Za-km-z]+$ ]]; then
        return 0
    else
        echo -e "${RED}❌ Invalid Base58 format: $address${NC}"
        return 1
    fi
}

# Function to check if address already has SOL
check_sol_balance() {
    local address=$1
    local balance=$(solana balance $address --url devnet 2>/dev/null | awk '{print $1}' | head -1)
    
    # Handle case where balance command fails (unfunded account)
    if [[ -z "$balance" ]] || [[ "$balance" == "0" ]] || [[ "$balance" == "Error:"* ]]; then
        echo "0"
    else
        echo "$balance"
    fi
}

# Function to check if address already has QUPDEV tokens
check_qupdev_balance() {
    local address=$1
    # Try to get token account info
    local token_account=$(spl-token accounts --owner $address --url devnet 2>/dev/null | grep $QUPDEV_MINT | awk '{print $1}' | head -1)
    
    if [[ -n "$token_account" ]]; then
        local balance=$(spl-token balance $token_account --url devnet 2>/dev/null | awk '{print $1}' | head -1)
        echo "${balance:-0}"
    else
        echo "0"
    fi
}

# Enhanced function to send tokens to one address
send_tokens() {
    local address=$1
    local user_num=$2
    local total_users=$3

    echo ""
    echo -e "${BLUE}👤 User $user_num/$total_users: ${address:0:8}...${address: -8}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check current balances
    local current_sol=$(check_sol_balance $address)
    local current_qupdev=$(check_qupdev_balance $address)
    
    echo -e "${BLUE}📊 Current balances: $current_sol SOL, $current_qupdev QUPDEV${NC}"

    # Step 1: Send devnet SOL (with retry logic)
    echo -e "${YELLOW}💎 Sending $SOL_AMOUNT devnet SOL...${NC}"
    local sol_attempts=0
    local sol_success=false
    
    while [[ $sol_attempts -lt 3 ]] && [[ "$sol_success" == "false" ]]; do
        sol_attempts=$((sol_attempts + 1))
        echo "   Attempt $sol_attempts/3..."
        
        if solana transfer $address $SOL_AMOUNT --allow-unfunded-recipient --url devnet --commitment confirmed >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Devnet SOL sent successfully!${NC}"
            sol_success=true
            
            # Wait a moment for the transaction to settle
            sleep 3
        else
            echo -e "${YELLOW}⚠️  SOL transfer attempt $sol_attempts failed${NC}"
            if [[ $sol_attempts -lt 3 ]]; then
                echo "   Retrying in 5 seconds..."
                sleep 5
            fi
        fi
    done

    if [[ "$sol_success" == "false" ]]; then
        echo -e "${RED}❌ Failed to send SOL after 3 attempts to $address${NC}"
        return 1
    fi

    # Step 2: Create token account with enhanced error handling
    echo -e "${YELLOW}🔧 Creating/verifying token account...${NC}"
    
    # First check if token account already exists
    local existing_account=$(spl-token accounts --owner $address --url devnet 2>/dev/null | grep $QUPDEV_MINT | awk '{print $1}' | head -1)
    
    if [[ -n "$existing_account" ]]; then
        echo -e "${GREEN}✅ Token account already exists: ${existing_account:0:8}...${existing_account: -8}${NC}"
    else
        # Create token account with retry
        local account_attempts=0
        local account_success=false
        
        while [[ $account_attempts -lt 3 ]] && [[ "$account_success" == "false" ]]; do
            account_attempts=$((account_attempts + 1))
            echo "   Creating token account - attempt $account_attempts/3..."
            
            if spl-token create-account $QUPDEV_MINT --owner $address --fee-payer $(solana address) --url devnet >/dev/null 2>&1; then
                echo -e "${GREEN}✅ Token account created successfully!${NC}"
                account_success=true
                sleep 2
            else
                echo -e "${YELLOW}⚠️  Token account creation attempt $account_attempts failed${NC}"
                if [[ $account_attempts -lt 3 ]]; then
                    sleep 3
                fi
            fi
        done

        if [[ "$account_success" == "false" ]]; then
            echo -e "${YELLOW}⚠️  Token account creation failed, but continuing (may exist)${NC}"
        fi
    fi

    # Step 3: Send QUPDEV tokens with retry logic
    echo -e "${YELLOW}🪙 Sending $TOKEN_AMOUNT QUPDEV tokens...${NC}"
    local token_attempts=0
    local token_success=false
    
    while [[ $token_attempts -lt 3 ]] && [[ "$token_success" == "false" ]]; do
        token_attempts=$((token_attempts + 1))
        echo "   Attempt $token_attempts/3..."
        
        if spl-token transfer $QUPDEV_MINT $TOKEN_AMOUNT $address --allow-unfunded-recipient --url devnet --fund-recipient >/dev/null 2>&1; then
            echo -e "${GREEN}✅ QUPDEV tokens sent successfully!${NC}"
            token_success=true
        else
            echo -e "${YELLOW}⚠️  Token transfer attempt $token_attempts failed${NC}"
            if [[ $token_attempts -lt 3 ]]; then
                echo "   Retrying in 5 seconds..."
                sleep 5
            fi
        fi
    done

    if [[ "$token_success" == "false" ]]; then
        echo -e "${RED}❌ Failed to send QUPDEV tokens after 3 attempts to $address${NC}"
        return 1
    fi

    # Step 4: Verify final balances
    echo -e "${YELLOW}🔍 Verifying final balances...${NC}"
    sleep 3  # Wait for blockchain to update
    
    local final_sol=$(check_sol_balance $address)
    local final_qupdev=$(check_qupdev_balance $address)
    
    echo -e "${GREEN}📊 Final balances: $final_sol SOL, $final_qupdev QUPDEV${NC}"

    # Log the successful distribution
    echo "$(date): SUCCESS - $TOKEN_AMOUNT QUPDEV + $SOL_AMOUNT SOL → $address (Final: $final_sol SOL, $final_qupdev QUPDEV)" >> token_distribution.log

    # Provide next steps
    echo -e "${GREEN}✅ Distribution complete!${NC}"
    echo -e "${BLUE}📱 Next steps for user:${NC}"
    echo -e "   1. Make sure wallet is on ${YELLOW}DEVNET${NC}"
    echo -e "   2. Visit: ${BLUE}$VAULT_URL${NC}"
    echo -e "   3. Connect wallet and start testing!"

    # Add delay between users to avoid rate limiting
    if [[ $user_num -lt $total_users ]]; then
        echo -e "${YELLOW}⏳ Waiting 5 seconds before next user...${NC}"
        sleep 5
    fi

    return 0
}

# Check our balances first with enhanced display
echo ""
echo -e "${BLUE}📊 Checking your balances...${NC}"
QUPDEV_BALANCE=$(spl-token balance $QUPDEV_MINT 2>/dev/null || echo "0")
SOL_BALANCE=$(solana balance | awk '{print $1}')
OUR_ADDRESS=$(solana address)

echo -e "${GREEN}💰 Your QUPDEV balance: $QUPDEV_BALANCE tokens${NC}"
echo -e "${GREEN}💎 Your SOL balance: $SOL_BALANCE SOL${NC}"
echo -e "${BLUE}🔑 Your address: $OUR_ADDRESS${NC}"

# Get wallet addresses
if [[ $# -eq 0 ]]; then
    # Interactive mode - no arguments provided
    echo ""
    echo -e "${YELLOW}📝 Interactive mode - Enter wallet addresses (one per line, empty line to finish):${NC}"
    ADDRESSES=()
    while true; do
        read -p "Wallet address $((${#ADDRESSES[@]} + 1)): " address
        if [[ -z "$address" ]]; then
            break
        fi
        if validate_address "$address"; then
            ADDRESSES+=("$address")
            echo -e "${GREEN}✅ Added: ${address:0:8}...${address: -8}${NC}"
        fi
    done
else
    # Command line arguments provided
    ADDRESSES=("$@")
    echo ""
    echo -e "${BLUE}📝 Processing ${#ADDRESSES[@]} addresses from command line...${NC}"
fi

# Validate all addresses first
echo ""
echo -e "${YELLOW}🔍 Validating addresses...${NC}"
VALID_ADDRESSES=()
for address in "${ADDRESSES[@]}"; do
    if validate_address "$address"; then
        VALID_ADDRESSES+=("$address")
        echo -e "${GREEN}✅ Valid: ${address:0:8}...${address: -8}${NC}"
    else
        echo -e "${RED}⚠️  Skipping invalid address: $address${NC}"
    fi
done

if [[ ${#VALID_ADDRESSES[@]} -eq 0 ]]; then
    echo -e "${RED}❌ No valid addresses to process!${NC}"
    echo ""
    echo -e "${YELLOW}Usage examples:${NC}"
    echo "  ./distribute_tokens.sh 9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"
    echo "  ./distribute_tokens.sh ADDR1 ADDR2 ADDR3"
    echo "  ./distribute_tokens.sh  (interactive mode)"
    exit 1
fi

# Check if we have enough tokens with safety margin
TOTAL_TOKENS_NEEDED=$((${#VALID_ADDRESSES[@]} * TOKEN_AMOUNT))
TOTAL_SOL_NEEDED=$(echo "${#VALID_ADDRESSES[@]} * $SOL_AMOUNT + 0.5" | bc)  # Add 0.5 SOL safety margin

echo ""
echo -e "${BLUE}📋 Distribution Summary:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}👥 Valid addresses: ${#VALID_ADDRESSES[@]}${NC}"
echo -e "${GREEN}🪙 QUPDEV needed: $TOTAL_TOKENS_NEEDED tokens${NC}"
echo -e "${GREEN}💎 SOL needed: $TOTAL_SOL_NEEDED SOL (includes safety margin)${NC}"
echo -e "${YELLOW}💰 QUPDEV available: $QUPDEV_BALANCE tokens${NC}"
echo -e "${YELLOW}💎 SOL available: $SOL_BALANCE SOL${NC}"

# Enhanced balance checking
if (( $(echo "$QUPDEV_BALANCE < $TOTAL_TOKENS_NEEDED" | bc -l) )); then
    echo ""
    echo -e "${RED}⚠️  WARNING: Insufficient QUPDEV tokens!${NC}"
    echo "Need: $TOTAL_TOKENS_NEEDED, Have: $QUPDEV_BALANCE"
    MINT_AMOUNT=$((TOTAL_TOKENS_NEEDED - QUPDEV_BALANCE + 10000))
    echo -e "${YELLOW}💡 Mint more with: spl-token mint $QUPDEV_MINT $MINT_AMOUNT${NC}"
    read -p "Continue anyway? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

if (( $(echo "$SOL_BALANCE < $TOTAL_SOL_NEEDED" | bc -l) )); then
    echo ""
    echo -e "${RED}⚠️  WARNING: Insufficient SOL!${NC}"
    echo "Need: $TOTAL_SOL_NEEDED, Have: $SOL_BALANCE"
    echo -e "${YELLOW}💡 Get more with: solana airdrop 5${NC}"
    read -p "Continue anyway? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Final confirmation
echo ""
echo -e "${YELLOW}🚀 Ready to send $SOL_AMOUNT SOL + $TOKEN_AMOUNT QUPDEV to ${#VALID_ADDRESSES[@]} addresses?${NC}"
echo -e "${BLUE}📱 Each user will receive setup for: $VAULT_URL${NC}"
read -p "Proceed? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo -e "${GREEN}🚀 Starting enhanced distribution...${NC}"

# Send tokens to each address
SUCCESS_COUNT=0
FAILED_ADDRESSES=()

for i in "${!VALID_ADDRESSES[@]}"; do
    address="${VALID_ADDRESSES[$i]}"
    user_num=$((i + 1))
    total_users=${#VALID_ADDRESSES[@]}

    if send_tokens "$address" "$user_num" "$total_users"; then
        ((SUCCESS_COUNT++))
    else
        FAILED_ADDRESSES+=("$address")
        echo "$(date): FAILED - $address" >> token_distribution.log
    fi
done

# Enhanced final summary
echo ""
echo -e "${GREEN}🎉 DISTRIBUTION COMPLETE!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Successful: $SUCCESS_COUNT addresses${NC}"
echo -e "${RED}❌ Failed: ${#FAILED_ADDRESSES[@]} addresses${NC}"

if [[ ${#FAILED_ADDRESSES[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}❌ Failed addresses:${NC}"
    for failed_addr in "${FAILED_ADDRESSES[@]}"; do
        echo "   $failed_addr"
    done
    echo ""
    echo -e "${YELLOW}💡 You can retry failed addresses with:${NC}"
    echo "   ./distribute_tokens.sh ${FAILED_ADDRESSES[*]}"
fi

if [[ $SUCCESS_COUNT -gt 0 ]]; then
    echo ""
    echo -e "${BLUE}📱 Enhanced message template for your community:${NC}"
    echo "════════════════════════════════════════════════════════════"
    echo -e "${GREEN}✅ Test tokens sent to $SUCCESS_COUNT users!${NC}"
    echo ""
    echo -e "${YELLOW}🚀 IMPORTANT SETUP STEPS:${NC}"
    echo "1. Switch your wallet to DEVNET (critical!)"
    echo "2. Visit: $VAULT_URL"
    echo "3. Connect your wallet"
    echo "4. You should see $TOKEN_AMOUNT QUPDEV tokens + $SOL_AMOUNT SOL"
    echo "5. Start testing and share results!"
    echo ""
    echo -e "${BLUE}💡 Troubleshooting:${NC}"
    echo "• No tokens? Check you're on DEVNET"
    echo "• Connection issues? Refresh and reconnect wallet"
    echo "• Transaction fails? Wait 30 seconds and try again"
    echo ""
    echo -e "${GREEN}🎁 Complete testing to earn real QUP rewards!${NC}"
    echo -e "${YELLOW}💬 Questions? Ask in the chat! 🚀${NC}"
    echo "════════════════════════════════════════════════════════════"
fi

echo ""
echo -e "${BLUE}📊 Distribution logged to: token_distribution.log${NC}"
echo -e "${BLUE}🔍 Check vault activity: https://explorer.solana.com/address/FGCLTzWpKHmPLcak8HcqP7j7wz7jjLTWzZ1SwKNFfzuz?cluster=devnet${NC}"
echo ""
echo -e "${GREEN}🎯 Happy testing! 🚀${NC}"
