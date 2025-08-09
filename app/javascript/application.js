// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

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