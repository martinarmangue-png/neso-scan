const CACHE_NAME = 'physio-scan-20260606-8';
const APP_SHELL = [
  './',
  './index.html',
  './scan.html',
  './dashboard-v2.html',
  './app-v2.html',
  './manifest.webmanifest',
  './manifest-v2.webmanifest',
  './neso-icon.svg'
];

const NAVIGATION_FALLBACKS = new Map([
  ['/app-v2.html', './app-v2.html'],
  ['/scan.html', './scan.html'],
  ['/dashboard-v2.html', './dashboard-v2.html'],
  ['/index.html', './index.html'],
  ['/', './index.html']
]);

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(
      keys
        .filter((key) => key !== CACHE_NAME)
        .map((key) => caches.delete(key))
    ))
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  const requestUrl = new URL(event.request.url);

  if (event.request.mode === 'navigate' && requestUrl.origin === self.location.origin) {
    event.respondWith(
      fetch(event.request).catch(() => {
        const fallback = NAVIGATION_FALLBACKS.get(requestUrl.pathname) || './index.html';
        return caches.match(fallback);
      })
    );
    return;
  }

  event.respondWith(
    fetch(event.request)
      .then((response) => {
        const copy = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
        return response;
      })
      .catch(() => caches.match(event.request).then((cached) => cached || caches.match('./index.html')))
  );
});
