module Api
  class BaseController
    protect_from_forgery with: :null_session
  end
end
