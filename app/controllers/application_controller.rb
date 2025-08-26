class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_account
  helper_method :theme_class

  private

    def set_current_account
      raw = params[:account]
      account_identifier = if raw.is_a?(ActionController::Parameters) || raw.is_a?(Hash)
        nil
      else
        raw
      end

      account_id = account_identifier || params[:account_id] || session[:account] || request.subdomains.first

      Current.account = Account.resolve(account_id)
      session[:account] = Current.account&.id

      head :unauthorized and return unless Current.account
    end

    def theme_class
      theme = Current.account&.theme.presence || 'light'
      "theme-#{theme}"
    end

end
