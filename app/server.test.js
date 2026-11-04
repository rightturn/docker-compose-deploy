'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { createServer } = require('./server');

function request(server, path, method = 'GET') {
  return new Promise((resolve, reject) => {
    const { port } = server.address();
    const req = require('node:http').request({ port, path, method }, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(data) }));
    });
    req.on('error', reject);
    req.end();
  });
}

test('endpoints', async (t) => {
  const server = createServer();
  await new Promise((r) => server.listen(0, r));
  t.after(() => server.close());

  const health = await request(server, '/health');
  assert.strictEqual(health.status, 200);
  assert.strictEqual(health.body.status, 'ok');

  const root = await request(server, '/');
  assert.strictEqual(root.status, 200);

  const missing = await request(server, '/nope');
  assert.strictEqual(missing.status, 404);

  const wrongMethod = await request(server, '/', 'POST');
  assert.strictEqual(wrongMethod.status, 405);
});
