class Api::ApiController < ActionController::Base
  skip_before_action :verify_authenticity_token
  before_action :user_token_authentication

  protected

  def current_organization
    if current_user == 'expired'
      render json: {status: "error", message: "User not signed in. Please signin to continue."}
    else
      current_user&.organization
    end
  end

  def current_department
    current_user&.department
  end

  def current_executive
    current_user&.department&.executives.find_by(at_office: "1");
  end

  def current_fiscal_year
    current_user&.organization&.fiscal_years.find_by(current: "1");
  end

  def is_citizen
    current_user.has_role?(Role::Citizen)
  end
  def is_admin
    current_user.has_role?(Role::Admin)
  end
  def is_user
    current_user.has_role?(Role::User)
  end
  def is_supervisor
    current_user.has_role?(Role::Supervisor)
  end
  def is_super_admin
    current_user.has_role?(Role::SuperAdmin)
  end

  helper_method :current_organization, :current_department, :current_fiscal_year, :current_executive, :is_citizen, :is_admin, :is_user, :is_supervisor, :is_super_admin

  private

  def current_user
    header_token = request.headers[:HTTP_AUTHORIZATION]
    if header_token && header_token != "Bearer "
      token = header_token.split(' ').last
      begin
        decoded = JWT.decode token, Rails.application.secret_key_base, true, { algorithm: 'HS256' }
        user    = User.find(decoded.first["user_id"])
        user
      rescue JWT::ExpiredSignature
        'expired'
      rescue JWT::VerificationError
        'invalid'
      end
    else
      nil
    end
  end

  def user_token_authentication
    message = current_user
    if message == 'expired'
      render json: { error: 'Token has expired' }, status: 401
    elsif message == 'invalid'
      render json: { error: 'Invalid Token' }, status: 401
    elsif !message
      render json: { error: 'Auth token required' }, status: 400
    else
      message
    end
  end
end
