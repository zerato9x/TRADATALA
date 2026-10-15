// Lossless transport encoding for itch.io's documented Brotli handling.
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const crypto = require('node:crypto');
const root = path.resolve(process.argv[2]);
const web = path.join(root, 'web');
const verification = path.join(root, 'verification');
const packPath = path.join(web, 'index.pck');
const raw = fs.readFileSync(packPath);
const compressed = zlib.brotliCompressSync(raw, {
  params: { [zlib.constants.BROTLI_PARAM_QUALITY]: 9, [zlib.constants.BROTLI_PARAM_SIZE_HINT]: raw.length },
});
if (!zlib.brotliDecompressSync(compressed).equals(raw)) throw new Error('Brotli roundtrip mismatch');
if (compressed.length > 200000000) throw new Error('Compressed web pack still exceeds 200 MB');
const htmlPath = path.join(web, 'index.html');
let html = fs.readFileSync(htmlPath, 'utf8');
const marker = /const GODOT_CONFIG = (\{[^\n]+\});/;
const found = html.match(marker);
if (!found) throw new Error('Missing Godot web configuration');
const config = JSON.parse(found[1]);
config.mainPack = 'index.pck.br';
config.fileSizes['index.pck.br'] = raw.length;
delete config.fileSizes['index.pck'];
html = html.replace(marker, 'const GODOT_CONFIG = ' + JSON.stringify(config) + ';');
fs.mkdirSync(verification, { recursive: true });
fs.writeFileSync(path.join(web, 'index.pck.br'), compressed);
fs.renameSync(packPath, path.join(verification, 'web-uncompressed.pck'));
fs.writeFileSync(htmlPath, html);
const digest = data => crypto.createHash('sha256').update(data).digest('hex');
const metadata = { file: 'index.pck.br', contentEncoding: 'br', rawBytes: raw.length,
  bytes: compressed.length, rawSha256: digest(raw), sha256: digest(compressed), exactRoundtrip: true,
  hosting: 'itch.io sends Content-Encoding: br for .br files. Other hosts must do the same.' };
fs.writeFileSync(path.join(verification, 'web-transport.json'), JSON.stringify(metadata, null, 2) + '\n');
console.log('WEB TRANSPORT PASS ' + JSON.stringify(metadata));
