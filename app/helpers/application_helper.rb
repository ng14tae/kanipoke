module ApplicationHelper
  def page_title(title = "")
    base_title = "KANIDIAN POKER"
    title.present? ? "#{title} | #{base_title}" : base_title
  end

  def battle_share_text(battle)
    # current_userと勝者を比較
    if battle.winner == current_user
      "🦀🎉 カニポカで#{battle.opponent.display_name}に勝利！
#カニポカ #KANIPOKE \n"
    elsif battle.winner == battle.opponent
      "🦀💭 カニポカで#{battle.opponent.display_name}に敗北...次は勝つ！
#カニポカ #KANIPOKE \n"
    end
  end

  # カード画像のパスを返すメソッド
  def card_image_path(card_number)
    "/images/cards/#{card_number}.png"
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

  def button_classes(type: :primary, size: :medium)
    base = "inline-block font-black rounded-lg border-2 shadow-lg transition-all duration-200 transform hover:-translate-y-1 hover:scale-105 hover:shadow-2xl active:translate-y-0 active:scale-98"

    size_classes = case size
    when :small
      "text-sm px-4 py-2 min-w-[100px]"
    when :medium
      "text-base sm:text-lg px-6 sm:px-8 py-3 sm:py-3.5 min-w-[120px]"
    when :large
      "text-lg sm:text-xl px-8 sm:px-10 py-4 sm:py-5 min-w-[140px]"
    end

    color_classes = case type
    when :primary
      "bg-yellow-400 text-blue-900 border-yellow-500 hover:bg-orange-500 hover:border-orange-600"
    when :secondary
      "bg-gray-500 text-white border-gray-600 hover:bg-gray-600 hover:border-gray-700"
    when :danger
      "bg-red-500 text-white border-red-600 hover:bg-red-600 hover:border-red-700"
    end

    "#{base} #{size_classes} #{color_classes}"
  end

  def form_input_classes
    "w-4/5 max-w-[200px] mx-auto block px-3 py-2 sm:py-2.5 border-2 border-gray-300 rounded-md text-sm sm:text-base text-gray-800 transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
  end

  # フォームラベルの共通クラス
  def form_label_classes
    "block text-xs sm:text-sm font-medium text-gray-700 mb-1"
  end

  # ユーザーカードの共通クラス
  def user_card_classes
    "bg-white bg-opacity-10 backdrop-blur-sm rounded-xl border-2 border-yellow-300 border-opacity-50 shadow-lg p-6 sm:p-10 transition-all duration-300 hover:shadow-2xl hover:scale-105"
  end

  # ソートボタンの共通クラス
  def sort_button_classes(active: false)
    base = "px-4 py-3 rounded-lg font-semibold text-sm transition-all duration-200"
    active ? "#{base} bg-yellow-400 text-blue-900" : "#{base} bg-gray-700 text-white hover:bg-gray-600"
  end

  # ランキングバッジ
  def ranking_badge(index)
    case index
    when 0 then "🥇 1位"
    when 1 then "🥈 2位"
    when 2 then "🥉 3位"
    else "#{index + 1}位"
    end
  end

  # ランキングボタンの共通クラス
  def ranking_button_classes(active: false)
    base = "px-4 py-2 rounded-lg font-semibold transition-colors duration-200"
    active ? "#{base} bg-yellow-400 text-blue-900" : "#{base} bg-gray-600 text-white hover:bg-gray-500"
  end

  # 戦績データの取得（ハッシュとオブジェクトの両方に対応）
  def battle_stat(user_data, key)
    user_data.is_a?(Hash) ? user_data[key] : user_data.send("weekly_#{key}")
  end

  # タブボタンの共通クラス
  def tab_button_classes(active: false)
    base = "px-6 py-3 font-semibold text-sm transition-all duration-200 relative"
    if active
      "#{base} bg-white bg-opacity-20 text-yellow-300 border-b-4 border-yellow-400"
    else
      "#{base} text-gray-300 hover:text-white hover:bg-white hover:bg-opacity-10"
    end
  end
end
