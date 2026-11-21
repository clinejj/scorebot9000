module ApplicationHelper
  PLATFORM_NAME = "Scorebot 9000".freeze

  # The brand in the header: the series on series/event pages and custom
  # domains, otherwise the platform.
  def brand_series
    @series || (@event&.series)
  end

  def site_name
    brand_series&.name || PLATFORM_NAME
  end

  def site_root_path
    brand_series ? series_home_path(brand_series) : root_path
  end

  def series_home_path(series)
    request.host.delete_prefix("www.") == series.custom_domain ? "/" : series_path(series)
  end

  def brand_initials
    return "S9" unless brand_series

    brand_series.name.scan(/\b[A-Za-z0-9]/).first(2).join.upcase
  end

  # Inline CSS variables for the current theme.
  def theme_style
    themed = @event || brand_series
    accent = content_for(:brand_accent).presence || themed&.accent_color
    return "" unless accent

    ink = themed&.accent_ink_color || "#ffffff"
    "--brand-accent: #{accent}; --brand-accent-ink: #{ink};"
  end

  def event_date(event, format: :long)
    time = event.local_starts_at or return nil
    case format
    when :short then time.strftime("%b %-d, %Y")
    else time.strftime("%A, %B %-d, %Y · %-l:%M %p %Z")
    end
  end

  def status_pill(event)
    label, classes =
      case event.status
      when "live" then [ "Live", "bg-red-600 text-white" ]
      when "published" then [ "Upcoming", "bg-stone-900 text-white dark:bg-white dark:text-stone-900" ]
      when "draft" then [ "Draft", "bg-amber-200 text-amber-950" ]
      else [ "Final", "bg-stone-200 text-stone-700 dark:bg-stone-800 dark:text-stone-200" ]
      end
    tag.span(class: "inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-bold uppercase tracking-wider #{classes}") do
      safe_join([ (tag.span(class: "h-1.5 w-1.5 animate-pulse rounded-full bg-white") if event.live?), label ].compact)
    end
  end

  def sms_number
    Rails.configuration.x.sms_number
  end

  def sms_instructions?(event)
    sms_number.present? && event.sms_code.present? && !event.finished? && event.sms_scoring_enabled?
  end
end
