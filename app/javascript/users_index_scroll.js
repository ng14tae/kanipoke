
document.addEventListener('DOMContentLoaded', function() {
    const SCROLL_KEY = 'usersIndexScrollPos';

    // ページ読み込み時：保存された位置に戻る
    function restoreScrollPosition() {
        const scrollPos = localStorage.getItem(SCROLL_KEY);
        if (scrollPos && scrollPos !== '0') {
        setTimeout(() => {
            window.scrollTo({
            top: parseInt(scrollPos),
            behavior: 'smooth'
            });
            console.log(`スクロール位置を復元: ${scrollPos}px`);
        }, 150);
        }
    }

    restoreScrollPosition();

    // スクロール時：位置を保存
    let ticking = false;
    function saveScrollPosition() {
        if (!ticking) {
        requestAnimationFrame(function() {
            const currentPos = window.scrollY;
            localStorage.setItem(SCROLL_KEY, currentPos);
            ticking = false;
        });
        ticking = true;
        }
    }

    window.addEventListener('scroll', saveScrollPosition);

    // ページ離脱時にも保存
    window.addEventListener('beforeunload', function() {
        localStorage.setItem(SCROLL_KEY, window.scrollY);
    });

    // 対戦ボタンクリック時にスクロール位置を保存
    document.querySelectorAll('a[href*="battles"]').forEach(button => {
        button.addEventListener('click', function() {
        localStorage.setItem(SCROLL_KEY, window.scrollY);
        });
    });
});