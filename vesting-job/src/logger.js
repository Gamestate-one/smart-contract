const winston = require('winston');
const DailyRotateFile = require('winston-daily-rotate-file');

const loggerFilename = '/var/logs/marketplace-scan-service/collection/create.log';

const opts = {
  filename: loggerFilename ,
  datePattern: 'YYYY-MM-DD',
  zippedArchive: true
};


const logger = winston.createLogger({
  format: winston.format.combine(
    winston.format.splat(),
    winston.format.timestamp({
      format: 'YYYY-MM-DD HH:mm:ss'
    }),
    winston.format.colorize(),
    winston.format.printf(
      log => {
        if(log.stack) return `[${log.timestamp}] [${log.level}] ${log.stack}`;
        return  `[${log.timestamp}] [${log.level}] ${log.message}`;
      },
    ),
  ),
  transports: [
    new winston.transports.Console(),
    new DailyRotateFile(opts)
  ],
});

module.exports = logger;
