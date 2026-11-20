module ApplicationHelper
  def site_name
    "Scorebot 9000"
  end

  def site_root_path
    root_path
  end

  # Inline CSS variables for the current theme (overridden by series/event themes).
  def theme_style
    accent = content_for(:brand_accent).presence
    accent ? "--brand-accent: #{accent};" : ""
  end
end
