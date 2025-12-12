document.addEventListener("turbo:load", () => {
    const fabBtn = document.getElementById("fab-button");
    const fabMenu = document.getElementById("fab-menu");

    if (!fabBtn || !fabMenu) return;

    fabBtn.addEventListener("click", () => {
        fabMenu.classList.toggle("hidden");
    });
});
