class PagesController < ApplicationController
  def home
    @live_events = Event.live.includes(:series).order(:starts_at).limit(6)
    @upcoming_events = Event.upcoming.includes(:series).order(:starts_at).limit(6)
    @recent_events = Event.recent_results.includes(:series).limit(6)
    @series_list = Series.joins(:events).merge(Event.listed).distinct.order(:name).limit(8)
  end

  def privacy
  end

  def sms_terms
  end
end
