class Api::PasswordsController < Api ::V1::ApiController
  skip_before_action :user_token_authentication, except: [:change]

  def forgot
    @user = User.find_by(email: params[:email])
    if @user.present?
      otp = SecureRandom.hex(3)
      @user.update(otp_code: otp)
      #send otp to user email
      UserMailer.password_reset(@user.email, otp).deliver_later
      # service to send otp as sms to user's phone
      # SmsSender.new(@user).send_otp_sms
      render json: {message: "Password reset code sent to #{params[:email]}.", otp: otp}
    else
      render json: {message: "User with email #{params[:email]} doesn't exist."}, status: 400
    end
  end

  def create
    @user = User.where(email: params[:email]).first
    if @user.present?
      if @user.otp_code == params[:otp]
        if params[:password].nil? || params[:password_confirmation].nil?
          render json: {message: "Password/ Password Confirmation cannot be empty."}
        elsif @user.update(password: params[:password] ,password_confirmation: params[:password_confirmation], pass_changed: 'true')
          render json: {message: "Password updated successfully"}
        else
          render json: {message: @user.errors.full_messages}, status: 400
        end
      else
        render json: {message: "Wrong OTP Code."}, status: 400
      end
    else
      render json: {message: "User with email #{params[:email]} doesn't exist."}, status: 400
    end
  end

  def change
    if current_user.valid_password? params[:current_password]
      if current_user.update(password: params[:password] ,password_confirmation: params[:password_confirmation], pass_changed: 'true')
        render json: {message: "password updated successfully"}
      else
        render json: {message: "Error while updating password."+current_user.errors.full_messages}, status: 400
      end
    else
      render json: {message: "Wrong Password."}, status: 400
    end
  end
end
