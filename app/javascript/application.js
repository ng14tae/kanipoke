import "@hotwired/turbo-rails"
import "./controllers"
// import "./scroll_position"
// import "./users_index_scroll"

document.addEventListener("turbo:load", function () {
    // FAB ボタンのバインド（モバイル・デスクトップ共通）
    const fabBtn = document.getElementById("fab-button");
    const fabMenu = document.getElementById("fab-menu");

    if (fabBtn && fabMenu) {
        fabBtn.addEventListener("click", () => {
            fabMenu.classList.toggle("hidden");
        });
    }
});

// Register service worker only in production to avoid dev/LAN environments
try {
    const envMeta = document.querySelector('meta[name="rails-env"]')?.content;
    const isProduction = envMeta === 'production';

    if ('serviceWorker' in navigator && isProduction) {
        window.addEventListener('load', () => {
            navigator.serviceWorker.register('/service-worker.js')
                .then(registration => console.log('Service Worker registered:', registration))
                .catch(error => console.log('Service Worker registration failed:', error));
        });
    }
} catch (e) {
    // defensive: don't block app if DOM isn't ready
}