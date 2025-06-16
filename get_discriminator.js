const anchor = require('@coral-xyz/anchor');
const crypto = require('crypto');

function getInstructionDiscriminator(name) {
    const preimage = `global:${name}`;
    const hash = crypto.createHash('sha256').update(preimage).digest();
    return hash.slice(0, 8);
}

// Calculate the correct discriminator for initialize_vault
const discriminator = getInstructionDiscriminator('initialize_vault');
console.log('initialize_vault discriminator:', Array.from(discriminator));
console.log('As buffer:', discriminator);
