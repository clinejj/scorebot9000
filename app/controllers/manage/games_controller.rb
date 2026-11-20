class Manage::GamesController < Manage::EventScopedController
  before_action :set_game, only: %i[edit update destroy move]

  def index
    @games = @event.games.to_a
    @game = @event.games.build
  end

  def create
    @game = @event.games.build(game_params)
    if @game.save
      redirect_to manage_event_games_path(@event), notice: "Added #{@game.name} as game #{@game.position}."
    else
      @games = @event.games.reload.to_a
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @game.update(game_params)
      redirect_to manage_event_games_path(@event), notice: "Saved #{@game.name}."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @game.score_entries.exists?
      redirect_to manage_event_games_path(@event), alert: "#{@game.name} has scores; lock it instead of deleting."
    else
      @game.destroy!
      renumber!
      redirect_to manage_event_games_path(@event), notice: "Deleted #{@game.name}."
    end
  end

  # Players text game numbers, so reordering is locked once the event is live.
  def move
    return redirect_to(manage_event_games_path(@event), alert: "Game numbers are locked once the event is live.") if @event.live? || @event.finished?

    games = @event.games.to_a
    index = games.index(@game)
    target = params[:direction] == "up" ? index - 1 : index + 1
    if target.between?(0, games.size - 1)
      games[index], games[target] = games[target], games[index]
      reposition!(games)
    end
    redirect_to manage_event_games_path(@event)
  end

  private
    def set_game
      @game = @event.games.find_by!(position: params[:position])
    end

    def game_params
      params.expect(game: [ :name, :description, :scheduled_at, :direction, :score_format, :participation,
        :team_aggregation, :team_aggregation_n, :attempt_policy, :weight, :status ])
    end

    def renumber!
      reposition!(@event.games.reload.to_a)
    end

    # Positions are unique per event, so shift everything out of the way first.
    def reposition!(games)
      Game.transaction do
        games.each_with_index { |game, index| game.update_columns(position: 10_000 + index) }
        games.each_with_index { |game, index| game.update_columns(position: index + 1) }
      end
      @event.touch
    end
end
