// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import "./scroll_position"
import "./users_index_scroll"

if ('serviceWorker' in navigator) {
window.addEventListener('load', () => {
    navigator.serviceWorker.register('/service-worker.js')
    .then(registration => {
        console.log('Service Worker registered:', registration);
    })
    .catch(error => {
        console.log('Service Worker registration failed:', error);
    });
});
}