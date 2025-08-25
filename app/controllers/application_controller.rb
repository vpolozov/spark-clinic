class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_account

  private

    def set_current_account
      account_id = params[:account] || session[:account] || request.subdomains.first

      Current.account = Account.resolve(account_id)
      session[:account] = Current.account&.id

      head :unauthorized and return unless Current.account
    end

end
