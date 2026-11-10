'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');

function withServer(fn) {
  return new Promise((resolve, reject) => {
    const server = app.listen(0, async () => {
      try {
        await fn(server.address().port);
        resolve();
      } catch (err) {
        reject(err);
      } finally {
        server.close();
      }
    });
  });
}

test('GET /health returns ok', () =>
  withServer(async (port) => {
    const res = await fetch(`http://127.0.0.1:${port}/health`);
    assert.equal(res.status, 200);
    assert.deepEqual(await res.json(), { status: 'ok' });
  }));

test('GET / returns the service name', () =>
  withServer(async (port) => {
    const res = await fetch(`http://127.0.0.1:${port}/`);
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.service, 'secure-cicd-demo');
  }));
