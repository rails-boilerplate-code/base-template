# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    super
  end

  # POST /resource
  def create
    super do |resource|

      resource.create_stripe(params)

      # resource.create_customer(params[:stripe_token], params[:user][:email])
      # resource.stripe_token = params[:stripe_token]

      # if params[:user][:pro] == "true"
      #   # plan_per_month_49 = 'plan_EwVQly9FL4X04W' # test
      #   plan_per_month_49 = 'plan_FEVxZLrZi57Mt6' #live
      #   resource.create_subscription(plan_per_month_49)
      #   resource.total_searches = 2000
      #   resource.plan_pro = true
      # else
      #   # plan_per_month_29 = 'plan_FCzyMMdsyW5Bff' # test
      #   plan_per_month_29 = 'plan_FEVwkrgnFAFUyh' #live
      #   resource.create_subscription(plan_per_month_29)
      #   resource.total_searches = 500
      #   resource.plan_individual = true
      # end
      #
      # resource.current_searches = 0
      # resource.searches_started_at = Date.today

      resource.save

      # if resource.save
      #   Spawnling.new do
      #     AdminMailer.new_user_sign_up(resource).deliver
      #   end
      # end
    end
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
