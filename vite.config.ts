import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import fs from 'fs';
import https from 'https';
import http from 'http';
import {defineConfig, Plugin} from 'vite';

function downloadFile(url: string, dest: string): Promise<{ success: boolean; error?: string; bytes?: number }> {
  return new Promise((resolve) => {
    const client = url.startsWith('https') ? https : http;
    client.get(url, (res) => {
      if (res.statusCode && res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return downloadFile(res.headers.location, dest).then(resolve);
      }
      if (res.statusCode !== 200) {
        return resolve({ success: false, error: `HTTP ${res.statusCode}` });
      }
      const file = fs.createWriteStream(dest);
      let bytes = 0;
      res.on('data', (chunk) => {
        bytes += chunk.length;
      });
      res.pipe(file);
      file.on('finish', () => {
        file.close(() => resolve({ success: true, bytes }));
      });
      file.on('error', (err) => {
        fs.unlink(dest, () => {});
        resolve({ success: false, error: err.message });
      });
    }).on('error', (err) => {
      resolve({ success: false, error: err.message });
    });
  });
}

function videoApiPlugin(): Plugin {
  return {
    name: 'video-backend-api',
    configureServer(server) {
      server.middlewares.use('/api/video-status', (req, res) => {
        const mp4Path = path.resolve(__dirname, 'public/game-video.mp4');
        const movPath = path.resolve(__dirname, 'public/game-video.mov');
        let exists = false;
        let url = null;
        let size = 0;
        let format = '';

        if (fs.existsSync(mp4Path) && fs.statSync(mp4Path).size > 100000) {
          exists = true;
          url = '/game-video.mp4';
          size = fs.statSync(mp4Path).size;
          format = 'mp4';
        } else if (fs.existsSync(movPath) && fs.statSync(movPath).size > 100000) {
          exists = true;
          url = '/game-video.mov';
          size = fs.statSync(movPath).size;
          format = 'mov';
        }

        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ exists, size, url, format }));
      });

      server.middlewares.use('/api/upload-video', (req, res) => {
        if (req.method === 'POST') {
          const dest = path.resolve(__dirname, 'public/game-video.mov');
          const fileStream = fs.createWriteStream(dest);
          let bytes = 0;
          req.on('data', (chunk) => {
            bytes += chunk.length;
          });
          req.pipe(fileStream);
          fileStream.on('finish', () => {
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify({ success: true, path: '/game-video.mov', bytes }));
          });
          fileStream.on('error', (err) => {
            res.statusCode = 500;
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify({ success: false, error: err.message }));
          });
        } else {
          res.statusCode = 405;
          res.end();
        }
      });

      server.middlewares.use('/api/pull-github', (req, res) => {
        if (req.method === 'POST') {
          let body = '';
          req.on('data', (chunk) => { body += chunk; });
          req.on('end', async () => {
            try {
              const data = JSON.parse(body || '{}');
              let targetUrl = data.url || 'https://raw.githubusercontent.com/bparlette/Aistudio/main/ScreenRecording_09-02-2026%2022-08-41_1.mov';
              if (targetUrl.includes('github.com') && targetUrl.includes('/blob/')) {
                targetUrl = targetUrl.replace('github.com', 'raw.githubusercontent.com').replace('/blob/', '/');
              }
              const dest = path.resolve(__dirname, 'public/game-video.mov');
              const result = await downloadFile(targetUrl, dest);
              res.setHeader('Content-Type', 'application/json');
              res.end(JSON.stringify(result));
            } catch (e: any) {
              res.statusCode = 500;
              res.setHeader('Content-Type', 'application/json');
              res.end(JSON.stringify({ success: false, error: e.message }));
            }
          });
        } else {
          res.statusCode = 405;
          res.end();
        }
      });
    }
  };
}

export default defineConfig(() => {
  return {
    plugins: [react(), tailwindcss(), videoApiPlugin()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '.'),
      },
    },
    server: {
      // HMR is disabled in AI Studio via DISABLE_HMR env var.
      // Do not modifyâfile watching is disabled to prevent flickering during agent edits.
      hmr: process.env.DISABLE_HMR !== 'true',
      // Disable file watching when DISABLE_HMR is true to save CPU during agent edits.
      watch: process.env.DISABLE_HMR === 'true' ? null : {},
    },
  };
});
