const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 5173;
const FLUTTER_DIR = path.join(__dirname, 'build', 'web');
const SITE_DIR = path.join(__dirname, 'site', 'public');
const APK_PATH = path.join(__dirname, 'build', 'app', 'outputs', 'flutter-apk', 'app-debug.apk');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.wasm': 'application/wasm',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.apk': 'application/vnd.android.package-archive',
};

const server = http.createServer((req, res) => {
  let reqPath = decodeURIComponent(req.url.split('?')[0]);

  // APK download routes
  if (reqPath === '/app-debug.apk' || reqPath === '/vitalert.apk' || reqPath === '/download') {
    if (fs.existsSync(APK_PATH)) {
      res.writeHead(200, {
        'Content-Type': 'application/vnd.android.package-archive',
        'Content-Disposition': 'attachment; filename="vitalert.apk"',
        'Access-Control-Allow-Origin': '*',
      });
      return fs.createReadStream(APK_PATH).pipe(res);
    }
  }

  // 1. If requesting root or /app, serve the Flutter Application
  if (reqPath === '/' || reqPath === '' || reqPath === '/app' || reqPath === '/flutter') {
    return serveFile(res, path.join(FLUTTER_DIR, 'index.html'));
  }

  // 2. Check if the file exists in FLUTTER_DIR
  const flutterCandidate = path.join(FLUTTER_DIR, reqPath);
  if (fs.existsSync(flutterCandidate) && fs.statSync(flutterCandidate).isFile()) {
    return serveFile(res, flutterCandidate);
  }

  // 3. Check if the file exists in SITE_DIR
  const siteCandidate = path.join(SITE_DIR, reqPath);
  if (fs.existsSync(siteCandidate) && fs.statSync(siteCandidate).isFile()) {
    return serveFile(res, siteCandidate);
  }

  // Check with .html appended
  if (fs.existsSync(siteCandidate + '.html') && fs.statSync(siteCandidate + '.html').isFile()) {
    return serveFile(res, siteCandidate + '.html');
  }

  // 4. Default fallback: serve Flutter index.html for Flutter SPA routing
  return serveFile(res, path.join(FLUTTER_DIR, 'index.html'));
});

function serveFile(res, filePath) {
  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      filePath = path.join(FLUTTER_DIR, 'index.html');
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    fs.readFile(filePath, (readErr, content) => {
      if (readErr) {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('500 Internal Server Error');
        return;
      }

      res.writeHead(200, {
        'Content-Type': contentType,
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0',
        'Pragma': 'no-cache',
        'Expires': '0',
      });
      res.end(content);
    });
  });
}

server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n======================================================`);
  console.log(`📱 FLUTTER MOBILE APP is LIVE at:`);
  console.log(`👉 Wi-Fi Mobile View:      http://192.168.1.5:${PORT}/`);
  console.log(`👉 Localhost View:         http://localhost:${PORT}/`);
  console.log(`\n📦 ANDROID APK DIRECT DOWNLOAD:`);
  console.log(`👉 Download APK:           http://192.168.1.5:${PORT}/vitalert.apk`);
  console.log(`======================================================\n`);
});
