namespace :scoring do
  desc "Print an event's results as a scrubbed scoring-preview sample: EVENT=<slug>"
  task export_sample: :environment do
    event = Event.find_by!(slug: ENV.fetch("EVENT"))
    $stdout.write Scoring::SampleExport.to_json(event)
  end
end
