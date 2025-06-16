// Add this to your existing frontend JavaScript

const TOKEN_REGISTRY = {
    "8bjKA2mkXMdkUHC6m8TfyQcksTDLKeP61XmFFcVViYef": {
        symbol: "QUPDEV",
        name: "QUP Development Token",
        decimals: 9,
        logoURI: "https://drinqup.com/qupdev-logo.png"
    }
};

function getTokenInfo(mintAddress) {
    return TOKEN_REGISTRY[mintAddress] || {
        symbol: "UNKNOWN",
        name: "Unknown Token",
        decimals: 9
    };
}

// Override token display
window.getTokenInfo = getTokenInfo;
window.TOKEN_REGISTRY = TOKEN_REGISTRY;
