module ResultsHelper
  def medal_badge(config, index, count: nil)
    return "" if index.nil?

    medal = config.medals[index] or return ""
    tag.span(count || (index + 1).ordinalize, class: "medal", style: "background-color: #{medal["color"] || "#78716c"}", title: medal["name"])
  end

  def medal_header(config, index)
    medal = config.medals[index]
    tag.span(class: "inline-flex items-center gap-1") do
      safe_join([ tag.span(class: "inline-block h-3 w-3 rounded-full", style: "background-color: #{medal["color"]}"), tag.span(medal["name"], class: "sr-only sm:not-sr-only") ])
    end
  end

  def points(value)
    return "—" if value.nil?

    ScoreValue.trim(BigDecimal(value.to_s).round(2))
  end

  def game_value(game, value)
    ScoreValue.format(value, game.score_format)
  end

  def competitor_name(event, competitor, link: true)
    dot = tag.span(class: "inline-block h-2.5 w-2.5 shrink-0 rounded-full", style: "background-color: #{competitor.color || "#a8a29e"}")
    label = tag.span(competitor.name, class: "truncate")
    content = tag.span(class: "inline-flex min-w-0 items-center gap-2") { safe_join([ dot, label ]) }
    if link && competitor.team? && competitor.public_id
      link_to content, event_team_path(event, competitor.public_id), class: "hover:underline"
    else
      content
    end
  end

  def standings_metric_label(config)
    {
      "medal_table" => "Pts", "weighted_medals" => "Pts", "medal_count" => "Medals",
      "placement_points" => "Pts", "average_rank" => "Avg place", "normalized_average" => "Score"
    }.fetch(config.standings_method, "Total")
  end

  def place_label(row)
    row.place ? row.place.to_s : "—"
  end
end
