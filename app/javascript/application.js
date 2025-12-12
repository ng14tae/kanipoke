import "@hotwired/turbo-rails"
import "./controllers"
// import "./scroll_position"
// import "./users_index_scroll"
import "./fab_menu";

document.addEventListener("turbo:load", function () {
    const btn = document.getElementById("menu-btn");
    const menu = document.getElementById("mobile-menu");

    if (btn && menu) {
        btn.addEventListener("click", () => {
            menu.classList.toggle("hidden"); // メニューの表示・非表示を切り替える
        });
    }
});

if ('serviceWorker' in navigator && location.hostname !== 'localhost' && location.hostname !== '127.0.0.1') {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/service-worker.js')
        .then(registration => console.log('Service Worker registered:', registration))
        .catch(error => console.log('Service Worker registration failed:', error));
    });
}