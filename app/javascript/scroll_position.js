document.addEventListener('DOMContentLoaded', function() {
  // 「降りる」リンクを取得
    const foldLinks = document.querySelectorAll('a[href*="users"]');

    foldLinks.forEach(link => {
        link.addEventListener('click', function(e) {
        // 現在保存されているスクロール位置を確認
        const currentScrollPos = localStorage.getItem('usersIndexScrollPos');
        console.log('現在保存されているスクロール位置:', currentScrollPos);

        // もしスクロール位置が保存されていなければ、デフォルト値を設定
        if (!currentScrollPos) {
            localStorage.setItem('usersIndexScrollPos', '0');
        }
        });
    });
});