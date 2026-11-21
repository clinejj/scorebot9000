# Old clinelympics.com URLs (summary.jsp?e=N, medals.jsp, scores.jsp,
# details.jsp, ...) redirect permanently to the new pages (plan section 10.4).
class LegacyRedirectsController < ApplicationController
  def show
    series = Series.for_host(request.host) || Series.find_by(slug: Legacy::Importer::SERIES_SLUG)
    return redirect_to(root_path, status: :moved_permanently) unless series

    event = params[:e].present? ? series.events.find_by(legacy_event_id: params[:e].to_i) : series.latest_event
    destination =
      case params[:page]
      when "summary", "medals", "scores" then event ? results_event_path(event) : root_path
      when "details" then event ? event_path(event) : root_path
      when "admin" then root_path
      else root_path
      end
    redirect_to destination, status: :moved_permanently
  end
end
