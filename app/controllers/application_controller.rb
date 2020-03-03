class ApplicationController < ActionController::API
  def render_error(code:, message:)
    render json: {
      message: message
    }, status: code
  end
end
