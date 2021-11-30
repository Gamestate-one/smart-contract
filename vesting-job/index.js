require('dotenv').config();
const fs = require("fs");
const csv = require("csv-parser");

const logger = require('./src/logger');

const Web3      = require('web3');
const endpoint  = process.env.LIVE_NET == 'TESTNET' ? process.env.ENDPOINT_TESTNET : process.env.ENDPOINT_MAINNET;
const web3      = new Web3(endpoint);

const abi       = require('./abiVesting.json');
const address   = process.env.CONTRACT_ADDRESS;
const contract  = new web3.eth.Contract(abi, address);

const walletsPath = 'wallet.csv';
const admin = require('./.secret.json');

let wallets = [];
let results = [];

async function readCSVFile(path) {
    let results = new Array();
    return new Promise((resolve, reject) => {
        fs.createReadStream(path)
        .pipe(csv())
        .on("data", (data) => {
            if(wallets.includes(data.wallet)) {
                logger.info('error duplicate ', data.wallet);
            } else {
                results.push(data.wallet.toLowerCase())
                wallets.push(data.wallet);
            }
        })
        .on("end", ()=>{ logger.info('successfully'); resolve(results); })
    })
}

const claimState = async (wallet, amount) => {
        const tx        = contract.methods.claim(
            wallet.toLowerCase(), 
            amount
        );
        const networkId = await web3.eth.net.getId();
        const gas       = await tx.estimateGas({from: admin.wallet.toLowerCase()});;
        const gasPrice  = await web3.eth.getGasPrice();
        const data      = tx.encodeABI();
        const nonce     = await web3.eth.getTransactionCount(admin.wallet.toLowerCase());
        
        const signedTx  = await web3.eth.accounts.signTransaction(
            {
            to: contract.options.address.toLowerCase(), 
            data,
            gas,
            gasPrice,
            nonce, 
            value: 0,
            chainId: networkId
            },
            admin.privateKey
        );
        
        const receipt   = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);

        logger.info(`Transaction hash:  ${receipt.transactionHash}`);
}

(async function() {
    results = await readCSVFile(walletsPath);
    let n = results.length;
    // logger.info(results);
    while( n > 0 ) {
        try {
            logger.info(n-1);
            await claimState(results[(n-1)], '-1'); // -1 = claim all amount
            n--;
        } catch (error) {
            logger.error(error.message);
        }
    }
    console.log('successfully');
}())
