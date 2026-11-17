'use strict';

const fs = require('fs');
const path = require('path');

const markerPath = process.env.ART_T1204_005_MARKER;

if (!markerPath) {
  throw new Error('ART_T1204_005_MARKER is not defined');
}

const markerDirectory = path.dirname(markerPath);
fs.mkdirSync(markerDirectory, { recursive: true });
fs.writeFileSync(
  markerPath,
  `Atomic Red Team T1204.005 synthetic npm lifecycle execution. Node PID: ${process.pid}\r\n`,
  { encoding: 'utf8', flag: 'wx' }
);

console.log(`Created Atomic Red Team marker: ${markerPath}`);

