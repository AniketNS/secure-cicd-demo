'use strict';

const express = require('express');

const app = express();
app.disable('x-powered-by');

app.get('/', (_req, res) => {
  res.json({ service: 'secure-cicd-demo', message: 'Hello from a protected pipeline' });
});

app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok' });
});

module.exports = app;
