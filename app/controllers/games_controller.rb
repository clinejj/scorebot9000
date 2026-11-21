class GamesController < ApplicationController
  include EventLookup

  before_action :set_event

  def show
    @game = @event.games.find_by!(position: params[:position])
    @result = @event.standings
    @game_result = @result.game_results.find { |game_result| game_result.game.position == @game.position }
  end
end
