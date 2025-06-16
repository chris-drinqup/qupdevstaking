// Add this to your React app to make QUPDEV tokens show up correctly

// 1. Create a token registry
const TOKEN_REGISTRY = {
  // Your devnet token
  "8bjKA2mkXMdkUHC6m8TfyQcksTDLKeP61XmFFcVViYef": {
    symbol: "QUPDEV",
    name: "QUP Development Token",
    decimals: 9,
    logoURI: "https://drinqup.com/qupdev-logo.png",
    network: "devnet"
  },
  // Add your future mainnet token here when ready
  // "YOUR_MAINNET_MINT_ADDRESS": {
  //   symbol: "QUP",
  //   name: "QUP Token", 
  //   decimals: 9,
  //   logoURI: "https://drinqup.com/qup-logo.png",
  //   network: "mainnet"
  // }
};

// 2. Helper function to get token info
const getTokenInfo = (mintAddress) => {
  return TOKEN_REGISTRY[mintAddress] || {
    symbol: "UNKNOWN",
    name: "Unknown Token",
    decimals: 9,
    logoURI: null
  };
};

// 3. Update your balance fetching logic
const fetchTokenBalance = async (connection, walletPublicKey) => {
  try {
    const tokenAccounts = await connection.getParsedTokenAccountsByOwner(
      walletPublicKey,
      {
        programId: TOKEN_PROGRAM_ID,
      }
    );

    let qupdevBalance = 0;
    
    // Look specifically for your token mint
    const qupdevAccount = tokenAccounts.value.find(account => 
      account.account.data.parsed.info.mint === "8bjKA2mkXMdkUHC6m8TfyQcksTDLKeP61XmFFcVViYef"
    );
    
    if (qupdevAccount) {
      qupdevBalance = qupdevAccount.account.data.parsed.info.tokenAmount.uiAmount;
    }
    
    return qupdevBalance;
  } catch (error) {
    console.error("Error fetching token balance:", error);
    return 0;
  }
};

// 4. Display component
const TokenBalance = ({ balance, mintAddress }) => {
  const tokenInfo = getTokenInfo(mintAddress);
  
  return (
    <div className="token-balance">
      {tokenInfo.logoURI && (
        <img src={tokenInfo.logoURI} alt={tokenInfo.symbol} width="24" height="24" />
      )}
      <span>{balance} {tokenInfo.symbol}</span>
      <small>{tokenInfo.name}</small>
    </div>
  );
};

// 5. Usage in your main component
const App = () => {
  const [qupdevBalance, setQupdevBalance] = useState(0);
  
  useEffect(() => {
    if (wallet.connected) {
      fetchTokenBalance(connection, wallet.publicKey)
        .then(setQupdevBalance);
    }
  }, [wallet.connected]);
  
  return (
    <div>
      <TokenBalance 
        balance={qupdevBalance} 
        mintAddress="8bjKA2mkXMdkUHC6m8TfyQcksTDLKeP61XmFFcVViYef" 
      />
    </div>
  );
};
