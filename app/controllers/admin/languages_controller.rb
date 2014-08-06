class Admin::LanguagesController < AdminController
  before_filter :ensure_editor!
  before_filter :fetch_language, only: [:edit, :update, :destroy]

  def index
    @languages = Language.all
  end

  def new
    @language = Language.new
  end

  def edit
  end

  def create
    @language = Language.new permitted_params
    if @language.save
      flash[:notice] = 'Language created successfully'
      redirect_to admin_languages_path
    else
      flash[:error] = @language.errors.full_messages.to_sentence
      render :new
    end
  end

  def update
    if @language.update permitted_params
      flash[:notice] = 'Language updated successfully'
      redirect_to admin_languages_path
    else
      flash[:error] = @language.errors.full_messages.to_sentence
      render :edit
    end
  end

  def destroy
    if @language.destroy
      flash[:notice] = 'Language deleted successfully'
    else
      flash[:error] = 'An error occurred while trying to delete that language'
    end
    redirect_to admin_languages_path
  end

  protected

  def permitted_params
    params.require(:language).permit(:name)
  end

  def fetch_language
    @language = Language.find params[:id]
  end
end