module Api
  class BaseController < ApplicationController
    protect_from_forgery with: :null_session

    # APIs often use JSON only
    before_action { request.format = :json }
  end
end
