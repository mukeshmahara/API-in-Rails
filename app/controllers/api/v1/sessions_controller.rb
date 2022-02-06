class Api::SessionsController < Api::V1::ApiController
  skip_before_action :user_token_authentication, only: [:create, :refresh]

  def create
    if User.where(email: params[:email]).present?
      @user = User.find_by(email: params[:email])
      if (@user.has_role?(Role::Supervisor) || @user.has_role?(Role::Admin) || @user.has_role?(Role::Citizen)) && @user&.valid_password?(params[:password])
        jwt           = JWT.encode(
            { user_id: @user.id, exp: (1.day.from_now).to_i },
            Rails.application.secret_key_base,
            'HS256'
        )
        refresh_token = JWT.encode(
            { user_id: @user.id },
            Rails.application.secret_key_base,
            'HS256'
        )
        user_details  = {}
        @user.attributes.each do |detail, value|
          user_details[detail] = value
        end
        id                              = @user._id.to_s
        o_id                            = @user.organization_id.to_s
        role_id                         = @user.role_ids.first.to_s
        user_details['_id']             = id
        user_details['organization_id'] = o_id
        user_details['role_ids']        = role_id


        department_details            = {}
        department_details['id']      = @user.department._id.to_s rescue ''
        department_details['name']    = @user.department.name rescue ''
        department_details['number']  = @user.department.number rescue ''
        department_details['address'] = @user.department.address rescue ''

        organization_details             = {}
        organization_details['id']       = @user.organization._id.to_s
        organization_details['name']     = @user.organization.name
        organization_details['province'] = @user.organization.province
        organization_details['address']  = @user.organization.address

        if params[:fcm_token] && !@user.fcm_tokens.include?(params[:fcm_token])
          fcm = @user.fcm_tokens.push(params[:fcm_token])
          @user.update(fcm_tokens: fcm)
        end

        render json: { token: jwt, organization: organization_details, department: department_details, expiry: 1.day.from_now.to_i, refresh_token: refresh_token, user: user_details.as_json }
      else
        render json: { message: 'wrong credentials' }, status: 400
      end
    else
      render json: { message: 'wrong email' }, status: 400
    end
  end

  def refresh
    if params[:refresh_token]
      decoded = JWT.decode params[:refresh_token], Rails.application.secret_key_base, true, { algorithm: 'HS256' }
      user    = User.find(decoded.first["user_id"])
      if user.present?
        jwt = JWT.encode(
            { user_id: user.id, exp: (1.day.from_now).to_i },
            Rails.application.secret_key_base,
            'HS256'
        )
        render json: { token: jwt, expiry: 1.day.from_now.to_i, message: 'Successfully generated new Token' }
      else
        render json: { error: 'Wrong Refresh Token' }, status: 400
      end
    else
      render json: { error: 'Refresh Token Nil' }, status: 400
    end
  end

  def fcm
    if request.headers[:fcm] && current_user.fcm_tokens.include?(request.headers[:fcm])
      fcm = current_user.fcm_tokens - [request.headers[:fcm]]
      if current_user.update(fcm_tokens: fcm)
        render json: { error: 'FCM token deleted successfully' }
      else
        render json: { error: 'Error while deleting fcm token' }, status: 400

      end
    else
      render json: { error: 'Error while processing request' }, status: 400
    end
  end

end