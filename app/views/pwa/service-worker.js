// Install イベント
self.addEventListener('install', (event) => {
  console.log('Service Worker installing.');
  self.skipWaiting(); // 新しい Service Worker を即座に有効化
});

// Activate イベント
self.addEventListener('activate', (event) => {
  console.log('Service Worker activated.');
  event.waitUntil(
    (async () => {
      await self.clients.claim(); // クライアントを制御
    })()
  );
});

// Fetch イベント
self.addEventListener('fetch', (event) => {
  console.log('Fetching:', event.request.url);

  event.respondWith((async () => {
    // GET リクエスト以外はキャッシュ処理をスキップ
    if (event.request.method !== 'GET') {
      console.log('Non-GET request, skipping cache:', event.request.url);
      return fetch(event.request);
    }

    const cache = await caches.open('my-cache');

    // キャッシュを確認
    const cachedResponse = await cache.match(event.request);
    if (cachedResponse) {
      console.log('Cache hit:', event.request.url);
      return cachedResponse;
    }

    // ネットワークから取得してキャッシュに保存
    try {
      const networkResponse = await fetch(event.request);
      console.log('Cache miss, fetching from network:', event.request.url);

      // GET リクエストのみキャッシュに保存
      if (event.request.method === 'GET') {
        cache.put(event.request, networkResponse.clone());
      }

      return networkResponse;
    } catch (err) {
      console.error('Fetch failed:', err);
      return Response.error();
    }
  })());
});