var chalk, dateformat;

chalk = require('chalk');

dateformat = require('dateformat');

module.exports = function() {
  var time;
  time = '[' + chalk.grey(dateformat(new Date, 'HH:MM:ss')) + ']';
  process.stdout.write(time + ' ');
  console.log.apply(console, arguments);
  return this;
};
