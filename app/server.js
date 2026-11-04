'use strict';

const http = require('node:http');

const VERSION = process.env.APP_VERSION || 'dev';
const STARTED_AT = new Date().toISOString();

function handler(req, res) {
  const send = (status, body) => {
    res.writeHead(status, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(body));
  };

  if (req.method !== 'GET') return send(405, { error: 'method not allowed' });

  switch (req.url) {
    case '/':
      return send(200, { message: 'Hello from docker-compose-deploy', version: VERSION });
    case '/health':
      return send(200, { status: 'ok', version: VERSION, startedAt: STARTED_AT });
    default:
      return send(404, { error: 'not found' });
  }
}

function createServer() {
  return http.createServer(handler);
}

if (require.main === module) {
  const port = Number(process.env.PORT || 3000);
  // A deliberately breakable switch used to demonstrate the automatic rollback.
  if (process.env.FAIL_ON_START === '1') {
    console.error('FAIL_ON_START is set: exiting');
    process.exit(1);
  }
  createServer().listen(port, '0.0.0.0', () => console.log(`listening on ${port}`));
}

module.exports = { createServer };
