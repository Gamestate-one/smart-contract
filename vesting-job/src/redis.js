require('dotenv').config();
const logger = require('./logger');

const redis = require("redis");

const client = redis.createClient({
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT
});

async function ensureKeyExists(keyName, initValue) {
    new Promise((resolve, reject) => {
        client.on('error', (err) => {
            logger.error('Redis Client Error' + err.message);
        });
        client.on('connect', () => logger.info('redis connected'));
        
        client.get(keyName, (err, value) => {
            if(err){logger.error('error get Key'); reject(err);}; 
            
            if(value) {
                resolve(value);
            } else {
                client.set(keyName, initValue, (err) => reject(err));
            }
        })
    })
}

async function updateKey(keyName, value) {
    new Promise((resolve, reject)=>{
        client.set(keyName, value, (err) => {
            logger.error('loi update');
            reject(err)});
        resolve()
    })
}

async function getValue(keyName) {
    new Promise((resolve, reject)=>{
        client.set(keyName, (err, value) => {
            if(value) {
                resolve(value);
            } else {
                reject(err);
            }
        });
    })
}

async function rpushQueue(queueName, data) {
    return new Promise((resolve, reject)=>{
        client.rpush(queueName, JSON.stringify(data), function(error, data){ 
            if(error) {
                logger.error('loi rpush')
                reject(error);
            } else {
                resolve(data);
            }
        });
    })
}

async function lpopQueue(queueName) {
    return new Promise((resolve, reject) => {
        client.lpop(queueName, (error, data) => {
            if(error) { 
                logger.error('loi lpop')
                reject(error); 
            } else { 
                resolve(data); 
            }
        })
    })
}

module.exports = {
    ensureKeyExists,
    updateKey,
    getValue,
    rpushQueue,
    lpopQueue
}