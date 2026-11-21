class Manage::DashboardController < Manage::BaseController
  def show
    scope = current_user.platform_admin? ? Event.all : managed_events
    @events = scope.includes(:series).order(Arel.sql("CASE status WHEN 'live' THEN 0 WHEN 'published' THEN 1 WHEN 'draft' THEN 2 WHEN 'final' THEN 3 ELSE 4 END"), starts_at: :desc)
    @series_list = current_user.platform_admin? ? Series.order(:name) : Series.where(id: current_user.memberships.where(resource_type: "Series").select(:resource_id)).order(:name)
  end

  private
    def managed_events
      memberships = current_user.memberships
      Event.where(id: memberships.where(resource_type: "Event").select(:resource_id))
        .or(Event.where(series_id: memberships.where(resource_type: "Series").select(:resource_id)))
    end
end
