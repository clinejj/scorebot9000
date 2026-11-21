class SeriesController < ApplicationController
  def show
    @series = Series.for_host(request.host) || Series.find_by!(slug: params[:slug])
    @events = @series.public_events.includes(:official_snapshot).to_a
    @stats = SeriesStats.new(@series)
  end
end
