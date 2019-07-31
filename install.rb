gem "stripe"
gem "devise"
gem_group :development, :test do
  gem "dotenv-rails"
  gem "rubocop", "~> 0.71.0", require: false
end

after_bundle do

  # Setup
  template = "default"
  current_path = File.expand_path(File.dirname(__FILE__))

  # DotEnv Gem setup
  matcher = "Bundler.require(*Rails.groups)\n"
  inject_into_file("config/application.rb", after: "#{matcher}") do
    <<~"HEREDOC"
      Dotenv::Railtie.load
    HEREDOC
  end

  # ENV stubs
  run("touch .env")
  run("echo .env >> .gitignore")
  run("echo 'STRIPE_SECRET_KEY=' >> .env")
  run("echo 'STRIPE_PUBLISHABLE_KEY=' >> .env")
  run("echo 'STRIPE_PRODUCT_ID=' >> .env")
  run("echo 'STRIPE_SKU_ID=' >> .env")
  run("echo 'APP_NAME=#{@app_name.split("_").map(&:capitalize).join("")}' >> .env")
  run("echo 'EMAIL=' >> .env")
  run("echo 'SEND_GRID_USER=' >> .env")
  run("echo 'SEND_GRID_PASSWORD=' >> .env")
  run("echo 'SEND_GRID_DOMAIN=' >> .env")

  # Stripe payments
  initializer 'stripe.rb', <<-HEREDOC
    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
  HEREDOC

  # Devise authentication
  generate("devise:install")

  matcher = "Rails.application.configure do\n"
  inject_into_file("config/environments/development.rb", after: "#{matcher}") do
    <<~"HEREDOC"
      # Email settings
      config.action_mailer.perform_caching = false
      config.action_mailer.perform_deliveries = true
      config.action_mailer.raise_delivery_errors = true
      config.action_mailer.delivery_method = :smtp
      config.action_mailer.smtp_settings = {
          user_name: "\#{ENV['SEND_GRID_USER']}",
          password: "\#{ENV['SEND_GRID_PASSWORD']}",
          domain: "\#{ENV['SEND_GRID_DOMAIN']}",
          address: 'smtp.sendgrid.net',
          port: '587',
          authentication: :plain,
          enable_starttls_auto: true
      } 

    HEREDOC
  end

  matcher = "'please-change-me-at-config-initializers-devise@example.com'"
  gsub_file 'config/initializers/devise.rb', "#{matcher}", '"#{ENV[\'EMAIL\']}"'

  matcher = "class ApplicationController < ActionController::Base\n"
  inject_into_file("app/controllers/application_controller.rb", after: "#{matcher}") do
    <<~"HEREDOC"
      before_action :authenticate_user!
        
      def after_sign_in_path_for(resource_or_scope)
        stored_location_for(resource_or_scope) || dashboard_path
      end
    HEREDOC
  end

  # Devise users
  generate("devise User")
  generate("devise:views")

  # TODO: remove from templates dir and instead inject this
  path = "app/controllers/users"
  file = "registrations_controller.rb"
  run("mkdir -p #{path}")
  run("cp #{current_path}/../base-template/templates/#{template}/#{path}/#{file} #{path}/#{file}")

  gsub_file 'config/routes.rb', "devise_for :users", ""
  route('devise_for :users, controllers: { registrations: "users/registrations" }')

  matcher = "end"
  inject_into_file("app/models/user.rb", before: "#{matcher}") do
    <<~"HEREDOC"
        
      def stripe_order(params)
        email = params[:user][:email]
        create_customer(params[:stripe_token], email)
        pay(email)
      end
    
      # TODO: Abstract remote API calls
      def create_customer(source, email)
        self.stripe_customer = Stripe::Customer.create(source: source, email: email).id
      rescue Stripe::CardError => e
        errors.add(:payment, e.json_body[:error][:message])
      end
    
      # TODO: Abstract remote API calls
      def pay(email)
        order = Stripe::Order.create(customer: self.stripe_customer, currency: 'usd', email: email, items: [{ type: 'sku', parent: (ENV['STRIPE_SKU_ID']).to_s, quantity: 1 }])
        self.stripe_status = order.status        
        self.stripe_order_id = order.id
        payment = Stripe::Order.pay(stripe_order_id, { customer: stripe_customer } )
        self.stripe_status = payment.status
      end

    HEREDOC
  end

  # Landing Page
  generate(:controller, "Home", "index")
  route "root to: 'home#index'"
  gsub_file 'config/routes.rb', "get 'home/index'", ""
  matcher = "class HomeController < ApplicationController\n"
  inject_into_file("app/controllers/home_controller.rb", after: "#{matcher}") do
    <<~"HEREDOC"
      skip_before_action :authenticate_user! 

    HEREDOC
  end

  # Pricing Page
  generate(:controller, "Pricing", "index")
  route "get :pricing, to: 'pricing#index'"
  matcher = "class PricingController < ApplicationController\n"
  inject_into_file("app/controllers/pricing_controller.rb", after: "#{matcher}") do
    <<~"HEREDOC"
      skip_before_action :authenticate_user!

    HEREDOC
  end

  # Member Dashboard
  generate(:controller, "Dashboard", "index")
  route "get :dashboard, to: 'dashboard#index'"
  gsub_file 'config/routes.rb', "get 'dashboard/index'", ""

  # Database
  generate(:migration, "AddStripeFieldsToUser stripe_customer:string:index stripe_order_id:string:index stripe_status:string")
  rails_command("db:migrate")

  # Template
  source = "#{current_path}/templates/#{template}/app/views"
  destination = "#{current_path}/../#{@app_name}/app/views"
  FileUtils.copy_entry source, destination, preserve = true

  # Template Assets
  source = "#{current_path}/templates/#{template}/app/assets"
  destination = "#{current_path}/../#{@app_name}/app/assets"
  FileUtils.copy_entry source, destination, preserve = true

  # Template Licenses
  source = "#{current_path}/templates/#{template}/licenses"
  destination = "#{current_path}/../#{@app_name}/licenses"
  FileUtils.copy_entry source, destination, preserve = true

  # Rubocop
  rubocop_path = "#{current_path}/../base-template/templates/globals/.rubocop.yml"
  run("cp #{rubocop_path} ./.rubocop.yml")
  run("bundle exec rubocop -a")

  # Git
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit generated via BoilerplateCode.com' }

  # Done message
  puts "\n\n"
  puts "=~" * 40
  puts "Done!"
  puts "=~" * 40
  puts "\n\n"
end
