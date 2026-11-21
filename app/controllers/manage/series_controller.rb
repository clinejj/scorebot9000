class Manage::SeriesController < Manage::BaseController
  before_action :require_hosting!, only: %i[new create]
  before_action :set_series, only: %i[edit update]

  def new
    @series = Series.new
  end

  def create
    @series = Series.new(series_params)
    if @series.save
      Membership.create!(user: current_user, resource: @series, role: "owner")
      redirect_to manage_root_path, notice: "Created #{@series.name}. Add an event to it."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @pool = @series.default_alias_pool
  end

  def update
    if @series.update(series_params)
      add_alias_names
      redirect_to edit_manage_series_path(@series), notice: "Saved."
    else
      @pool = @series.default_alias_pool
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_series
      @series = Series.find_by!(slug: params[:slug])
      authorize! @series, to: :manage?
    end

    def series_params
      allowed = [ :name, :slug, :tagline, :description, :logo, :hero, :accent_color ]
      allowed << :custom_domain if current_user.platform_admin? # needs a Fly certificate + DNS
      params.expect(series: allowed)
    end

    def add_alias_names
      names = params.dig(:series, :alias_names).to_s
      return if names.blank?

      pool = @series.default_alias_pool || AliasPool.create!(name: "#{@series.name} names", owner: @series).tap { |created| @series.update!(default_alias_pool: created) }
      pool.add_names(names)
    end
end
