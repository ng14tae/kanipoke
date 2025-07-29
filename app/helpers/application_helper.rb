module ApplicationHelper
  def page_title(title = "")
    base_title = "KANIDIAN POKER"
    title.present? ? "#{title} | #{base_title}" : base_title
  end

  def battle_share_text(battle)
    # current_userと勝者を比較
    if battle.winner == current_user
      "🦀🎉 カニポカで#{battle.opponent.display_name}に勝利！
      #カニポカ #KANIDIAN_POKER"
    else battle.winner == battle.opponent
      "🦀💭 カニポカで#{battle.opponent.display_name}に敗北...次は勝つ！
      #カニポカ #KANIDIAN_POKER"
    endg
git   end

  # カード画像のパスを返すメソッド
  def card_image_path(card_number)
    "cards/#{card_number}.png"
  end

  # カード画像タグを生成するメソッド
  def card_image_tag(card_number, options = {})
    return placeholder_card_tag if card_number.nil?

    default_options = {
      alt: "カード#{card_number}",
      class: "card-image w-32 h-auto rounded-lg shadow-lg",
      loading: "lazy"
    }

    image_tag(card_image_path(card_number), default_options.merge(options))
  end

  # プレースホルダー（カードが選択されていない時）
  def placeholder_card_tag(options = {})
    default_options = {
      class: "card-placeholder w-32 h-40 bg-gray-200 rounded-lg flex items-center justify-center border-2 border-dashed border-gray-400"
    }

    content_tag(:div, default_options.merge(options)) do
      content_tag(:span, "?", class: "text-4xl text-gray-500 font-bold")
    end
  end
end
