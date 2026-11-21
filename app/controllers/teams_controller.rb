class TeamsController < ApplicationController
  include EventLookup

  before_action :set_event

  def show
    @team = @event.teams.find(params[:id])
    @members = @team.participants.order(:alias_name)
    @result = @event.standings
    @standing = (@result.standings + Array(@result.individual_standings)).find { |row| row.competitor.public_id == @team.public_id }
  end
end
