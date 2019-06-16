gem "stripe"
gem "devise"
gem_group :development, :test do
  gem "dotenv-rails"
  gem "rubocop", "~> 0.71.0", require: false
end

after_bundle do

  # Setup
  current_path = File.expand_path(File.dirname(__FILE__))

  # DotEnv Gem setup
  matcher = "Bundler.require(*Rails.groups)\n"
  inject_into_file("config/application.rb", after: "#{matcher}") do
    <<~"BERKELEY"
      Dotenv::Railtie.load
    BERKELEY
  end

  # ENV stubs and populate
  run("touch .env")
  run("echo .env >> .gitignore")

  puts "\n\n"
  puts "=~" * 40

  puts "For details on how to find these keys go here:"
  puts "<INSERT LINK TO VISUAL INSTRUCTIONS>\n" #TODO: insert link to instructions

  stripe_test_secret_key = ask("What is your Stripe Test Secret Key?")
  stripe_test_publish_key = ask("What is your Stripe Test Publishable Key?")

  run("echo 'STRIPE_SECRET_KEY=#{stripe_test_secret_key}' >> .env")
  run("echo 'STRIPE_PUBLISHABLE_KEY=#{stripe_test_publish_key}' >> .env")

  puts "=~" * 40
  puts "\n\n"

  # Stripe payments
  initializer 'stripe.rb', <<-HEREDOC
    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
  HEREDOC

  # Devise authentication
  generate("devise:install")
  environment 'config.action_mailer.default_url_options = { host: "localhost", port: 3000 }', env: 'development'
  matcher = "class ApplicationController < ActionController::Base\n"
  inject_into_file("app/controllers/application_controller.rb", after: "#{matcher}") do
    <<~"CALIFORNIA"
      before_action :authenticate_user!
    CALIFORNIA
  end

  # Devise users
  generate("devise User")
  path = "app/controllers/users"
  file = "registrations_controller.rb"
  run("mkdir -p #{path}")
  run("cp #{current_path}/../base-template/files/#{path}/#{file} #{path}/#{file}")
  gsub_file 'config/routes.rb', "devise_for :users", ""
  route('devise_for :users, controllers: { registrations: "users/registrations" }')

  # Main site
  generate(:controller, "Home", "index")
  route "root to: 'home#index'"
  gsub_file 'config/routes.rb', "get 'home/index'", ""

  # Member Dashboard
  generate(:controller, "Dashboard", "index")
  route "get :dashboard, to: 'dashboard#index'"
  gsub_file 'config/routes.rb', "get 'dashboard/index'", ""

  # Database
  rails_command("db:migrate")

  # Rubocop
  rubocop_path = "#{current_path}/../base-template/files/.rubocop.yml"
  run("cp #{rubocop_path} ./.rubocop.yml")
  # run("bundle exec rubocop -a")

  # Git
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit generated via BoilerplateCode.com' }
end
