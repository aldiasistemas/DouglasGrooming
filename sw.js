// Service worker de Douglas's Grooming.
// - La app carga de la red primero (asi siempre ves la version mas reciente).
// - Si no hay senal, abre la ultima copia guardada de la app.
// - NUNCA guarda datos de clientes: las consultas a la base de datos (supabase) no pasan por aqui.
const CACHE_NAME = 'douglas-v1';
const ARCHIVOS_BASE = ['./index.html', './config.js', './manifest.json', './logo.png', './icon-192.png', './icon-512.png'];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(ARCHIVOS_BASE)));
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((nombres) => Promise.all(nombres.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n))))
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.protocol !== 'http:' && url.protocol !== 'https:') return;
  if (url.hostname.endsWith('.supabase.co') || url.hostname.endsWith('.supabase.in')) return; // datos: siempre en vivo
  event.respondWith(
    fetch(req)
      .then((respuesta) => {
        if (respuesta && (respuesta.ok || respuesta.type === 'opaque')) {
          const copia = respuesta.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(req, copia)).catch(() => {});
        }
        return respuesta;
      })
      .catch(() => caches.match(req).then((guardada) => guardada || caches.match('./index.html')))
  );
});
