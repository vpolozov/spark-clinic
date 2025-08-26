class AccountsController < ApplicationController
  before_action :require_account

  # POST /account/switch
  def switch
    account = Account.resolve(params[:account])
    if account
      session[:account] = account.id
      redirect_to root_path, notice: "Switched to #{account.name}"
    else
      redirect_back fallback_location: root_path, alert: 'Account not found'
    end
  end

  # GET /account/edit
  def edit
    @account = Current.account
    @themes = %w[light dark ocean blue green]
  end

  # PATCH /account
  def update
    @account = Current.account
    if @account.update(account_params)
      redirect_to root_path, notice: 'Account updated'
    else
      @themes = %w[light dark ocean blue green]
      flash.now[:alert] = 'Could not update account'
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def require_account
    head :unauthorized unless Current.account
  end

  def account_params
    params.require(:account).permit(:name, :theme)
  end
end
