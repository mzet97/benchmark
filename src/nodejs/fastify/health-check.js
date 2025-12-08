const http = require('http');

const options = {
  hostname: 'localhost',
  port: 8080,
  path: '/health',
  method: 'GET',
  timeout: 3000
};

const request = http.request(options, (res) => {
  if (res.statusCode === 200 || res.statusCode === 503) {
    process.exit(0);
  } else {
    process.exit(1);
  }
});

request.on('error', () => {
  process.exit(1);
});

request.on('timeout', () => {
  request.destroy();
  process.exit(1);
});

request.end();
