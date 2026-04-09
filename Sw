// Return Manager Service Worker
// キャッシュ名にはバージョンを含める（サーバー側のファイル更新を検知するため）
const CACHE_NAME = 'return-manager-v1';
const URLS_TO_CACHE = ['/ryogoku-daily-report/warehouse_receive.html'];

// インストール時: キャッシュに保存
self.addEventListener('install', event => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(URLS_TO_CACHE))
  );
});

// アクティベート時: 古いキャッシュを削除
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// fetch時: キャッシュを優先（オフライン対応）
// ただしアップデートボタン押下時は network_first で動作
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request).then(cached => cached || fetch(event.request))
  );
});

// アップデートメッセージ受信: 最新版を取得してキャッシュを更新
self.addEventListener('message', event => {
  if (event.data === 'CHECK_UPDATE') {
    fetch('/ryogoku-daily-report/warehouse_receive.html', {cache: 'no-cache'})
      .then(res => {
        if (!res.ok) throw new Error('fetch failed');
        return caches.open(CACHE_NAME).then(cache => {
          cache.put('/ryogoku-daily-report/warehouse_receive.html', res.clone());
          event.source.postMessage('UPDATED');
        });
      })
      .catch(() => event.source.postMessage('ERROR'));
  }
});
