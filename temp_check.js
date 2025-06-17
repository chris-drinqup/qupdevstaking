        const VAULT_CONFIG = {
            programId: new solanaWeb3.PublicKey('69GqjmqyXcL593ByVF4YqrFzBxHX5DsVcSRsAk49pPq7'),
            vaultPda: new solanaWeb3.PublicKey('FGCLTzWpKHmPLcak8HcqP7j7wz7jjLTWzZ1SwKNFfzuz'),
            tokenVaultPda: new solanaWeb3.PublicKey('HCw3qKrvemEwYzAzozqtwBtdapsWe7GfeCKjrUUPNSQf'),
            qupdevMint: new solanaWeb3.PublicKey('8bjKA2mkXMdkUHC6m8TfyQcksTDLKeP61XmFFcVViYef'),
            stakeDiscriminator: [48, 191, 163, 44, 71, 129, 63, 164],
            unstakeDiscriminator: [90, 95, 107, 42, 205, 124, 50, 225],
            claimDiscriminator: [62, 198, 214, 193, 213, 159, 108, 210]
        };

        // Global state
        let wallet = null;
        let connection = null;
        let userTokenAccount = null;
        let provider = null;
        let selectedDuration = 0;
        let selectedAPY = 0;
        let calculatedAmount = 0;

        function initializeConnection() {
            if (typeof solanaWeb3 !== 'undefined') {
                connection = new solanaWeb3.Connection('https://api.devnet.solana.com', 'confirmed');
                return true;
            }
            return false;
        }

        function addLog(message, type = 'info') {
            const logs = document.getElementById('logs');
            const timestamp = new Date().toLocaleTimeString();
            const logEntry = document.createElement('div');
            logEntry.className = `log-entry log-${type}`;
            logEntry.innerHTML = `[${timestamp}] ${message}`;
            logs.appendChild(logEntry);
            logs.scrollTop = logs.scrollHeight;
        }

        function updateProgress(currentStep) {
            const steps = ['step1', 'step2', 'step3', 'step4'];
            steps.forEach((step, index) => {
                const element = document.getElementById(step);
                element.classList.remove('current', 'completed');
                if (index < currentStep - 1) {
                    element.classList.add('completed');
                } else if (index === currentStep - 1) {
                    element.classList.add('current');
                }
            });
        }

        function goToStep(stepNumber) {
            addLog(`Navigating to step ${stepNumber}`, 'info');

            document.getElementById('connectSection').style.display = 'none';
            document.getElementById('balanceSection').style.display = 'none';
            document.getElementById('calculatorSection').style.display = 'none';
            document.getElementById('stakingSection').style.display = 'none';
            document.getElementById('welcomeBackSection').style.display = 'none';

            switch(stepNumber) {
                case 1:
                    document.getElementById('connectSection').style.display = 'block';
                    updateProgress(1);
                    break;
                case 2:
                    if (!wallet) {
                        addLog('Please connect your wallet first!', 'warning');
                        alert('Please connect your wallet to proceed.');
                        goToStep(1);
                        return;
                    }
                    document.getElementById('balanceSection').style.display = 'block';
                    updateProgress(2);
                    break;
                case 3:
                    if (!wallet) {
                        addLog('Please connect your wallet first!', 'warning');
                        alert('Please connect your wallet to proceed.');
                        goToStep(1);
                        return;
                    }
                    if (!userTokenAccount) {
                        addLog('Please get test tokens first!', 'warning');
                        alert('Please request test tokens to proceed.');
                        goToStep(2);
                        return;
                    }
                    document.getElementById('calculatorSection').style.display = 'block';
                    updateProgress(3);
                    break;
                case 4:
                    if (!wallet) {
                        addLog('Please connect your wallet first!', 'warning');
                        alert('Please connect your wallet to proceed.');
                        goToStep(1);
                        return;
                    }
                    if (!userTokenAccount) {
                        addLog('Please get test tokens first!', 'warning');
                        alert('Please request test tokens to proceed.');
                        goToStep(2);
                        return;
                    }
                    if (calculatedAmount <= 0 || selectedDuration <= 0) {
                        addLog('Please plan your staking strategy first!', 'warning');
                        alert('Please select an amount and duration to proceed.');
                        goToStep(3);
                        return;
                    }
                    document.getElementById('stakingSection').style.display = 'block';
                    updateProgress(4);
                    break;
            }
        }

        async function connectWallet() {
            const connectBtn = document.getElementById('connectBtn');
            const walletStatus = document.getElementById('walletStatus');

            try {
                connectBtn.disabled = true;
                connectBtn.innerHTML = '<span class="loading"></span> Connecting...';
                addLog('Looking for Solana wallets...', 'info');

                if (window.solana && window.solana.isPhantom) {
                    provider = window.solana;
                    addLog('Phantom wallet detected!', 'success');
                } else if (window.solflare) {
                    provider = window.solflare;
                    addLog('Solflare wallet detected!', 'success');
                } else if (window.backpack) {
                    provider = window.backpack;
                    addLog('Backpack wallet detected!', 'success');
                } else {
                    throw new Error('No Solana wallet found! Please install Phantom, Solflare, or Backpack and ensure the extension is enabled.');
                }

                if (!provider.isConnected && !provider.publicKey) {
                    addLog('Wallet extension detected but not initialized. Please open the wallet and ensure it’s set to Devnet.', 'warning');
                    throw new Error('Wallet not initialized. Please open your wallet extension and set it to Devnet.');
                }

                const response = await provider.connect()                wallet = response.publicKey;

                const isDevnet = await connection.getRpcEndpoint().includes('devnet');
                if (!isDevnet) {
                    addLog('Wallet is not on Devnet! Please switch to Devnet in your wallet settings.', 'error');
                    provider.disconnect();
                    throw new Error('Please switch your wallet to Solana Devnet.');
                }

                addLog(`Wallet connected: ${wallet.toString()}`, 'success');

                connectBtn.innerHTML = 'Connected';
                connectBtn.style.background = '#4CAF50';
                walletStatus.innerHTML = `<div style="color: #4CAF50; font-weight: bold;">Connected: ${wallet.toString().slice(0, 8)}...${wallet.toString().slice(-8)}</div>`;

                document.getElementById('userAddress').textContent = wallet.toString();
                document.getElementById('balanceSection').style.display = 'block';

                updateProgress(2);
                await loadBalances();

            } catch (error) {
                addLog(`Connection failed: ${error.message}`, 'error');
                alert(`Failed to connect wallet: ${error.message}`);
                connectBtn.disabled = false;
                connectBtn.innerHTML = 'Connect Wallet';
                walletStatus.innerHTML = `<div style="color: #f56565;">${error.message}</div>`;
            }
        }

        async function loadBalances() {
            try {
                addLog('Loading your balances...', 'info');

                const solBalance = await connection.getBalance(wallet);
                const solFormatted = (solBalance / solanaWeb3.LAMPORTS_PER_SOL).toFixed(3);
                document.getElementById('solBalance').textContent = `${solFormatted} SOL`;

                try {
                    const tokenAccounts = await connection.getTokenAccountsByOwner(wallet, {
                        mint: VAULT_CONFIG.qupdevMint
                    });

                    if (tokenAccounts.value.length > 0) {
                        userTokenAccount = tokenAccounts.value[0].pubkey;
                        const tokenBalance = await connection.getTokenAccountBalance(userTokenAccount);
                        const qupdevBalance = tokenBalance.value.uiAmount || 0;

                        document.getElementById('qupdevBalance').textContent = `${qupdevBalance} QUPDEV`;

                        if (qupdevBalance === 0) {
                            document.getElementById('needTokens').style.display = 'block';
                            document.getElementById('hasTokens').style.display = 'none';
                            addLog('You need QUPDEV tokens to stake!', 'warning');
                        } else {
                            document.getElementById('hasTokens').style.display = 'block';
                            document.getElementById('needTokens').style.display = 'none';
                            document.getElementById('calculatorSection').style.display = 'block';
                            updateProgress(3);
                            addLog(`Found ${qupdevBalance} QUPDEV tokens - ready for staking!`, 'success');
                            await refreshStakeInfo();
                        }
                    } else {
                        document.getElementById('qupdevBalance').textContent = '0 QUPDEV';
                        document.getElementById('needTokens').style.display = 'block';
                        document.getElementById('hasTokens').style.display = 'none';
                        addLog('No QUPDEV token account found. Request test tokens!', 'warning');
                    }
                } catch (tokenError) {
                    document.getElementById('qupdevBalance').textContent = '0 QUPDEV';
                    document.getElementById('needTokens').style.display = 'block';
                    document.getElementById('hasTokens').style.display = 'none';
                    addLog('No QUPDEV tokens found. Request test tokens!', 'warning');
                }

            } catch (error) {
                addLog(`Failed to load balances: ${error.message}`, 'error');
                alert(`Error loading balances: ${error.message}`);
            }
        }

        function selectDuration(days, apy) {
            selectedDuration = days;
            selectedAPY = apy;

            document.querySelectorAll('.duration-option').forEach(option => {
                option.classList.remove('selected');
            });
            document.querySelector(`[data-duration="${days}"]`).classList.add('selected');

            calculateRewards();
            addLog(`Selected ${days} day plan with ${apy}% APY`, 'info');
        }

        function calculateRewards() {
            const amount = parseFloat(document.getElementById('stakeAmountCalc').value) || 0;

            if (amount > 0 && selectedAPY > 0) {
                const dailyRate = selectedAPY / 100 / 365;
                const dailyReward = amount * dailyRate;
                const totalReward = amount * (selectedAPY / 100) * (selectedDuration / 365);

                document.getElementById('dailyRewards').textContent = `${dailyReward.toFixed(4)} QUP`;
                document.getElementById('totalRewards').textContent = `${(amount + totalReward).toFixed(2)} QUP`;

                calculatedAmount = amount;
                document.getElementById('proceedBtn').disabled = false;
            } else {
                document.getElementById('dailyRewards').textContent = '0 QUP';
                document.getElementById('totalRewards').textContent = '0 QUP';
                document.getElementById('proceedBtn').disabled = true;
            }
        }

        function proceedToStaking() {
            if (calculatedAmount <= 0 || selectedDuration <= 0) {
                addLog('Please select amount and duration first!', 'error');
                alert('Please enter a valid amount and select a duration.');
                return;
            }

            const planHTML = `
                <h4>Your Staking Plan:</h4>
                <p><strong>Amount:</strong> ${calculatedAmount} QUPDEV</p>
                <p><strong>Duration:</strong> ${selectedDuration} days</p>
                <p><strong>APY:</strong> ${selectedAPY}%</p>
                <p><strong>Expected Daily Rewards:</strong> ${(calculatedAmount * selectedAPY / 100 / 365).toFixed(4)} QUP</p>
                <p><strong>Total After ${selectedDuration} Days:</strong> ${(calculatedAmount + calculatedAmount * selectedAPY / 100 * selectedDuration / 365).toFixed(2)} QUP</p>
            `;

            document.getElementById('stakingPlan').innerHTML = planHTML;
            document.getElementById('stakingSection').style.display = 'block';
            updateProgress(4);

            addLog('Ready to execute staking plan!', 'success');
        }

        async function executeStaking() {
            if (typeof solanaWeb3 === 'undefined') {
                addLog('Solana Web3.js library not loaded! Please refresh the page.', 'error');
                alert('Libraries still loading. Please wait a moment and try again.');
                return;
            }

            if (!wallet) {
                addLog('Please connect your wallet first!', 'error');
                alert('Please connect your wallet to proceed.');
                goToStep(1);
                return;
            }

            if (!userTokenAccount) {
                addLog('No QUPDEV token account found! Please request test tokens.', 'error');
                alert('Please request test tokens to proceed.');
                goToStep(2);
                return;
            }

            const solBalance = await connection.getBalance(wallet);
            const minSolRequired = 0.01 * solanaWeb3.LAMPORTS_PER_SOL;
            if (solBalance < minSolRequired) {
                addLog('Insufficient SOL for transaction fees! Need at least 0.01 SOL.', 'error');
                alert('Please request more SOL test tokens from chris@qupcorp.com.');
                return;
            }

            const tokenBalance = await connection.getTokenAccountBalance(userTokenAccount);
            const qupdevBalance = tokenBalance.value.uiAmount || 0;
            if (qupdevBalance < calculatedAmount) {
                addLog(`Insufficient QUPDEV tokens! You have ${qupdevBalance}, need ${calculatedAmount}.`, 'error');
                alert('Please request more QUPDEV test tokens.');
                return;
            }

            try {
                const executeBtn = document.getElementById('executeBtn');
                executeBtn.disabled = true;
                executeBtn.innerHTML = '<span class="loading"></span> Creating Transaction...';

                addLog(`Building staking transaction for ${calculatedAmount} QUPDEV...`, 'info');

                const userStakePda = getUserStakePda();
                const amountLamports = Math.floor(parseFloat(calculatedAmount) * 1e9);

                const amountBytes = new ArrayBuffer(8);
                const amountView = new DataView(amountBytes);
                amountView.setBigUint64(0, BigInt(amountLamports), true);

                const durationBytes = new ArrayBuffer(4);
                const durationView = new DataView(durationBytes);
                durationView.setUint32(0, selectedDuration, true);

                const discriminatorArray = new Uint8Array(VAULT_CONFIG.stakeDiscriminator);
                const amountArray = new Uint8Array(amountBytes);
                const durationArray = new Uint8Array(durationBytes);
                const instructionData = new Uint8Array(discriminatorArray.length + amountArray.length + durationArray.length);
                instructionData.set(discriminatorArray);
                instructionData.set(amountArray, discriminatorArray.length);
                instructionData.set(durationArray, discriminatorArray.length + amountArray.length);

                const stakeInstruction = new solanaWeb3.TransactionInstruction({
                    programId: VAULT_CONFIG.programId,
                    keys: [
                        { pubkey: wallet, isSigner: true, isWritable: false },
                        { pubkey: userTokenAccount, isSigner: false, isWritable: true },
                        { pubkey: VAULT_CONFIG.tokenVaultPda, isSigner: false, isWritable: true },
                        { pubkey: userStakePda, isSigner: false, isWritable: true },
                        { pubkey: VAULT_CONFIG.vaultPda, isSigner: false, isWritable: true },
                        { pubkey: VAULT_CONFIG.qupdevMint, isSigner: false, isWritable: false },
                        { pubkey: splToken.TOKEN_PROGRAM_ID, isSigner: false, isWritable: false },
                        { pubkey: solanaWeb3.SystemProgram.programId, isSigner: false, isWritable: false }
                    ],
                    data: instructionData
                });

                const transaction = new solanaWeb3.Transaction().add(stakeInstruction);
                const latestBlockhash = await connection.getLatestBlockhash();
                transaction.recentBlockhash = latestBlockhash.blockhash;
                transaction.feePayer = wallet;

                addLog('Requesting wallet signature...', 'info');

                const signedTx = await provider.signTransaction(transaction);
                const signature = await connection.sendRawTransaction(signedTx.serialize());

                addLog('Confirming transaction on Solana...', 'info');
                addLog(`Transaction: <span class="tx-link" onclick="openTx('${signature}')">${signature.slice(0, 8)}...${signature.slice(-8)}</span>`, 'info');

                const confirmation = await connection.confirmTransaction(signature, 'confirmed');

                if (confirmation.value.err) {
                    throw new Error(`Transaction failed: ${JSON.stringify(confirmation.value.err)}`);
                }

                addLog(`Staking successful! Your ${calculatedAmount} QUPDEV is now earning ${selectedAPY}% APY!`, 'success');
                addLog('Rewards start accumulating immediately!', 'success');

                document.getElementById('activeStakeSection').style.display = 'block';
                await refreshStakeInfo();
                await loadBalances();

            } catch (error) {
                addLog(`Staking failed: ${error.message}`, 'error');
                if (error.message.includes('insufficient funds')) {
                    addLog('Make sure you have enough SOL for transaction fees', 'warning');
                } else if (error.message.includes('rejected')) {
                    addLog('Transaction was rejected by wallet', 'warning');
                } else if (error.message.includes('Invalid account')) {
                    addLog('Check if the vault program and PDAs are correctly configured.', 'error');
                }
                alert(`Staking failed: ${error.message}`);
            } finally {
                const executeBtn = document.getElementById('executeBtn');
                executeBtn.disabled = false;
                executeBtn.innerHTML = 'Execute Staking Transaction';
            }
        }

        function getUserStakePda() {
            const [pda] = solanaWeb3.PublicKey.findProgramAddressSync(
                [
                    new TextEncoder().encode('user_stake'),
                    wallet.toBuffer(),
                    VAULT_CONFIG.vaultPda.toBuffer()
                ],
                VAULT_CONFIG.programId
            );
            return pda;
        }

        async function refreshStakeInfo() {
            if (!wallet) {
                addLog('Please connect your wallet to check stake info.', 'warning');
                return;
            }

            try {
                addLog('Checking your latest earnings...', 'info');

                const userStakePda = getUserStakePda();
                const userStakeAccount = await connection.getAccountInfo(userStakePda);

                if (userStakeAccount && userStakeAccount.data.length > 0) {
                    addLog('Found your active stake! Calculating your earnings...', 'success');

                    // Assumed data layout: [8 bytes discriminator, 8 bytes amount (u64), 8 bytes rewards (u64), 4 bytes start_time (u32)]
                    const data = userStakeAccount.data;
                    const stakedAmount = Number(data.readBigUInt64LE(8)) / 1e9;
                    const rewards = Number(data.readBigUInt64LE(16)) / 1e9;
                    const startTime = data.readUInt32LE(24);
                    const daysStaked = Math.floor((Date.now() / 1000 - startTime) / (24 * 3600));

                    document.getElementById('welcomeBackSection').style.display = 'block';
                    document.getElementById('activeStakeSection').style.display = 'block';

                    document.getElementById('stakedAmount').textContent = `${stakedAmount.toFixed(2)} QUP`;
                    document.getElementById('pendingRewards').textContent = `${rewards.toFixed(4)} QUP`;
                    document.getElementById('timeStaked').textContent = `${daysStaked} days`;

                    addLog(`Current earnings: ${rewards.toFixed(4)} QUP (and growing!)`, 'success');
                    addLog(`Staked for: ${daysStaked} days`, 'info');
                    addLog('Tip: The longer you wait, the more you earn!', 'info');

                } else {
                    document.getElementById('stakedAmount').textContent = '0 QUP';
                    document.getElementById('pendingRewards').textContent = '0 QUP';
                    document.getElementById('timeStaked').textContent = '0 days';
                    addLog('No active stake found. Ready to start earning?', 'info');
                }

            } catch (error) {
                addLog(`Failed to refresh stake info: ${error.message}`, 'error');
                alert(`Error refreshing stake info: ${error.message}`);
            }
        }

        async function claimRewards() {
            if (!wallet || !userTokenAccount) {
                addLog('Please connect your wallet and ensure you have a QUPDEV token account.', 'error');
                alert('Please connect your wallet and ensure you have test tokens.');
                goToStep(wallet ? 2 : 1);
                return;
            }

            try {
                const claimBtn = document.getElementById('claimBtn');
                claimBtn.disabled = true;
                claimBtn.innerHTML = '<span class="loading"></span> Claiming Rewards...';

                addLog('Claiming your earned rewards...', 'info');

                const userStakePda = getUserStakePda();
                const instructionData = new Uint8Array(VAULT_CONFIG.claimDiscriminator);

                const claimInstruction = new solanaWeb3.TransactionInstruction({
                    programId: VAULT_CONFIG.programId,
                    keys: [
                        { pubkey: wallet, isSigner: true, isWritable: false },
                        { pubkey: userTokenAccount, isSigner: false, isWritable: true },
                        { pubkey: VAULT_CONFIG.tokenVaultPda, isSigner: false, isWritable: true },
                        { pubkey: userStakePda, isSigner: false, isWritable: true },
                        { pubkey: VAULT_CONFIG.vaultPda, isSigner: false, isWritable: true },
                        { pubkey: VAULT_CONFIG.qupdevMint, isSigner: false, isWritable: false },
                        { pubkey: splToken.TOKEN_PROGRAM_ID, isSigner: false, isWritable: false }
                    ],
                    data: instructionData
                });

                const transaction = new solanaWeb3.Transaction().add(claimInstruction);
                const latestBlockhash = await connection.getLatestBlockhash();
                transaction.recentBlockhash = latestBlockhash.blockhash;
                transaction.feePayer = wallet;

                addLog('Requesting wallet signature...', 'info');

                const signedTx = await provider.signTransaction(transaction);
                const signature = await connection.sendRawTransaction(signedTx.serialize());

                addLog('Confirming transaction on Solana...', 'info');
                addLog(`Transaction: <span class="tx-link" onclick="openTx('${signature}')">${signature.slice(0, 8)}...${signature.slice(-8)}</span>`, 'info');

                const confirmation = await connection.confirmTransaction(signature, 'confirmed');

                if (confirmation.value.err) {
                    throw new Error(`Transaction failed: ${JSON.stringify(confirmation.value.err)}`);
                }

                addLog('Rewards claimed successfully! Check your wallet balance.', 'success');
                addLog('Your original staked tokens are still earning more rewards!', 'info');

                await refreshStakeInfo();
                await loadBalances();

            } catch (error) {
                addLog(`Failed to claim rewards: ${error.message}`, 'error');
                alert(`Failed to claim rewards: ${error.message}`);
            } finally {
                const claimBtn = document.getElementById('claimBtn');
                claimBtn.disabled = false;
                claimBtn.innerHTML = '🎁 Claim My Rewards';
            }
        }

        async function unstakeEverything() {
            if (!confirm('Are you sure you want to unstake everything? This will return all your tokens (original + rewards) to your wallet and stop earning new rewards.')) {
                return;
            }

            if (!wallet || !userTokenAccount) {
                addLog('Please connect your wallet and ensure you have a QUPDEV token account.', 'error');
                art('Please connect your wallet and ensure you have test tokens.');
                goToStep(wallet ? 2 : 1);
                return;
            }

            try {
                const unstakeBtn = document.getElementById('unstakeBtn');
                unstakeBtn.disabled = true;
                unstakeBtn.innerHTML = '<span class="loading"></span> Unstaking Everything...';

                addLog('Unstaking all your tokens...', 'info');

                const userStakePda = getUserStakePda();
                const instructionData = new Uint8Array(VAULT_CONFIG.unstakeDiscriminator);

                const unstakeInstruction = new solanaWeb3.TransactionInstruction({
                    programId: VAULT_CONFIG.programId,
                    keys: [
                        { pubkey: wallet, isSigner: true, isWritable: false },
                        { pubkey: userTokenAccount, isSigner: false, isWritable: true },
                        { pubkey: VAULT_CONFIG.tokenVaultPda, isSigner: false, isWritable: true },
                        { pubkey: userStakePda, isSigner: false, isWritable: true },
                        { pubkey: VAULT_CONFIG.vaultPda, isSigner: false, isWritable: true },
                        { pubkey: VAULT_CONFIG.qupdevMint, isSigner: false, isWritable: false },
                        { pubkey: splToken.TOKEN_PROGRAM_ID, isSigner: false, isWritable: false }
                    ],
                    data: instructionData
                });

                const transaction = new solanaWeb3.Transaction().add(unstakeInstruction);
                const latestBlockhash = await connection.getLatestBlockhash();
                transaction.recentBlockhash = latestBlockhash.blockhash;
                transaction.feePayer = wallet;

                addLog('Requesting wallet signature...', 'info');

                const signedTx = await provider.signTransaction(transaction);
                const signature = await connection.sendRawTransaction(signedTx.serialize());

                addLog('Confirming transaction on Solana...', 'info');
                addLog(`Transaction: <span class="tx-link" onclick="openTx('${signature}')">${signature.slice(0, 8)}...${signature.slice(-8)}</span>`, 'info');

                const confirmation = await connection.confirmTransaction(signature, 'confirmed');

                if (confirmation.value.err) {
                    throw new Error(`Transaction failed: ${JSON.stringify(confirmation.value.err)}`);
                }

                addLog('All tokens unstaked successfully! Everything is back in your wallet.', 'success');
                addLog('You can now use your tokens or stake them again for more rewards!', 'info');

                document.getElementById('activeStakeSection').style.display = 'none';
                document.getElementById('calculatorSection').style.display = 'block';
                updateProgress(3);

                await refreshStakeInfo();
                await loadBalances();

            } catch (error) {
                addLog(`Failed to unstake: ${error.message}`, 'error');
                alert(`Failed to unstake: ${error.message}`);
            } finally {
                const unstakeBtn = document.getElementById('unstakeBtn');
                unstakeBtn.disabled = false;
                unstakeBtn.innerHTML = '🏦 Unstake Everything';
            }
        }

        async function runQuickTest() {
            if (!wallet || !userTokenAccount) {
                addLog('Please connect your wallet and get test tokens first.', 'error);
                alert('Please connect your wallet and get test tokens to run the quick test.');
                goToStep(wallet ? 2 : 1);
                return;
            }

            addLog('Starting quick test - staking 25 QUPDEV for testing...', 'info');

            calculatedAmount = 25;
            selectedDuration = 1;
            selectedAPY = 12;

            const stakingPlan = document.getElementById('stakingPlan');
            if (stakingPlan) {
                stakingPlan.innerHTML = `
                    <h4>Quick Test Plan:</h4>
                    <p><strong>Amount:</strong> 25 QUPDEV</p>
                    <p><strong>Duration:</strong> Testing (1 minute)</p>
                    <p><strong>Purpose:</strong> Verify staking functionality</p>
                `;
            }

            const stakingSection = document.getElementById('stakingSection');
            if (stakingSection) {
                stakingSection.style.display = 'block';
            }

            await executeStaking();
        }

        function copyAddress() {
            if (wallet) {
                navigator.clipboard.writeText(wallet.toString());
                addLog('Wallet address copied! Now email it to chris@qupcorp.com', 'success');

                const copyBtn = document.querySelector('button[onclick="copyAddress()"]');
                const originalText = copyBtn.innerHTML;
                copyBtn.innerHTML = '✅ Copied!';
                copyBtn.style.background = '#4CAF50';

                setTimet(() => {
                    copyBtn.innerHTML = originalText;
                    copyBtn.style.background = '';
                }, 2000);
            }
        }

        function openEmailTemplate() {
            if (wallet) {
                const walletAddress = wallet.toString();
                const subject = encodeURIComponent('QUP Devnet Test Tokens Request');
                const body = encodeURIComponent(`Hi Chris,\n\nPlease send test tokens to my devnet wallet:\n\n${walletAddress}\n\nThanks!`);

                const mailtoLink = `mailto:chris@qupcorp.com?subject=${subject}&body=${body}`;
                window.open(mailtoLink);

                addLog('Email template opened! Send the email and wait for your tokens.', 'success');
            }
        }

        function openExplorer() {
            const url = `https://explorer.solana.com/address/${VAULT_CONFIG.vaultPda.toString()}?cluster=devnet`;
            window.open(url, '_blank');
            addLog('Opened vault in Solana Explorer', 'info');
        }

        function openTx(signature) {
            const url = `https://explorer.solana.com/tx/${signature}?cluster=devnet`;
            window.open(url, '_blank');
            addLog('Opened transaction in Solana Explorer', 'info');
        }

        async function checkVaultState() {
            if (!wallet) {
                addLog('Please connect your wallet first to check vault state!', 'error');
                alert('Please connect your wallet first!');
                goToStep(1);
                return;
            }

            try {
                addLog('Checking vault state on-chain...', 'info');
                const vaultAccount = await connection.getAccountInfo(VAULT_CONFIG.vaultPda);
                if (vaultAccount) {
                    addLog(`Vault exists: ${vaultAccount.data.length} bytes, ${vaultAccount.lamports} lamports`, 'success');
                    addLog(`Owner: ${vaultAccount.owner.toString()}`, 'info');
                    alert('Vault is active! Check the log for details.');
                } else {
                    addLog('Vault account not found!', 'error');
                    alert('Vault account not found on the blockchain!');
                }
            } catch (error) {
                addLog(`Failed to check vault state: ${error.message}`, 'error');
                alert(`Error checking vault: ${error.message}`);
            }
        }

        document.addEventListener('DOMContentLoaded', () => {
            // Reset global state
            wallet = null;
            connection = null;
            userTokenAccount = null;
            provider = null;
            selectedDuration = 0;
            selectedAPY = 0;
            calculatedAmount = 0;

            let attempts = 0;
            const maxAttempts = 20;

            function initializeApp() {
                if (typeof solanaWeb3 === 'undefined' || typeof splToken === 'undefined') {
                    attempts++;
                    if (attempts >= maxAttempts) {
                        addLog('Error: Solana libraries failed to load. Please check your internet or try again later.', 'error');
                        alert('Failed to load required libraries. Please refresh the page or check your connection.');
                        return;
                    }
                    addLog('Loading Solana libraries...', 'info');
                    setTimeout(initializeApp, 500);
                    return;
                }

                if (!initializeConnection()) {
                    addLog('Failed to initialize Solana connection', 'error');
                    return;
                }

                addLog('QUP Vault Staking Platform loaded!', 'success');
                addLog('Connect your wallet to start earning rewards on your QUP tokens!', 'info');
                updateProgress(1);

                connection.getVersion().then(version => {
                    addLog(`Connected to Solana devnet (${version['solana-core']})`, 'success');
                }).catch(error => {
                    addLog(`Failed to connect to devnet: ${error.message}`, 'error');
                });
            }

            initializeApp();
        });
