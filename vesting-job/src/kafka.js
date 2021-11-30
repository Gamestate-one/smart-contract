require('dotenv').config();

const kafkaUsername = process.env.KAFKA_SECURITY_USERNAME ? process.env.KAFKA_SECURITY_USERNAME : '';
const kafkaPassword = process.env.KAFKA_SECURITY_PASSWORD ? process.env.KAFKA_SECURITY_PASSWORD : '';
const KAFKA_SEVERS_CONFIG = process.env.KAFKA_SEVERS_CONFIG;
const sasl = kafkaUsername.length && kafkaPassword.length ? { 
    kafkaUsername, 
    kafkaPassword, 
    mechanism: process.env.KAFKA_SECURITY_PROTOCOL 
} : null;


const { Kafka } = require('kafkajs');

const kafkaConfig = {
	'clientId': 'blockchain-scan-event',
	'brokers': [KAFKA_SEVERS_CONFIG],
	'sasl': sasl,
	'ssl': false
};
// console.log(kafkaConfig);

const kafka = new Kafka(kafkaConfig);

const kafkaProducer = kafka.producer();

async function ensureTopicExists(topic) {
	const adminClient = kafka.admin();
	await adminClient.createTopics({
		topics: [{
			topic: topic
		}]
	});
}

async function sendKafkaMessage(msgBody, topic, msgKey) {
	await kafkaProducer.send({
		topic: topic,
		messages: [{
			key: msgKey,
			value: msgBody
		}]
	})
}

module.exports = {
    ensureTopicExists,
    sendKafkaMessage,
    kafkaProducer
}