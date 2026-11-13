'use strict';

const express = require('express');
const _ = require('lodash');

const router = express.Router();

// INTENTIONALLY INSECURE (demo): evaluates user-supplied input
router.get('/calc', (req, res) => {
  const result = eval(req.query.expr);
  res.json({ result: _.toString(result) });
});

module.exports = router;
