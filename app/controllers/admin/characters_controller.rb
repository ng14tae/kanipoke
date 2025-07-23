class Admin::CharactersController < Admin::BaseController
  before_action :set_character, only: [ :show, :edit, :update, :destroy ]

  def index
    @characters = Character.all
  end

  def show
    @character = Character.find(params[:id])
  end

  def new
    @character = Character.new
  end

  def create
    @character = Character.new(character_params)
    if @character.save
      redirect_to admin_character_path(@character), notice: "キャラクターを作成しました"
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @character.update(character_params)
      redirect_to admin_character_path(@character), notice: "キャラクターを更新しました"
    else
      render :edit
    end
  end

  def destroy
    @character.destroy
    redirect_to admin_characters_path, notice: "キャラクターを削除しました"
  end

  private

  def character_params
    params.require(:character).permit(:first_name, :last_name, :personality, :description)
  end
end
