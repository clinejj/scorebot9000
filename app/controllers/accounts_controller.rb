class AccountsController < ApplicationController
  require_authentication

  def show
    @participants = current_user.participants.includes(:team, event: :series).order("events.starts_at DESC NULLS LAST").references(:events)
  end

  def update
    if current_user.update(params.expect(user: [ :name ]))
      redirect_to account_path, notice: "Saved."
    else
      @participants = current_user.participants.includes(:team, :event)
      render :show, status: :unprocessable_entity
    end
  end
end
