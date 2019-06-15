gem "stripe"
gem "devise"
gem_group :development, :test do
  gem "dotenv-rails"
  gem "rubocop", "~> 0.71.0", require: false
end

after_bundle do

  # DotEnv Gem setup
  matcher = "Bundler.require(*Rails.groups)\n"
  inject_into_file("config/application.rb", after: "#{matcher}") do
    <<~"RUBY"
      Dotenv::Railtie.load
    RUBY
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
  initializer 'stripe.rb', <<-CODE
    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
  CODE

  # Devise authentication
  generate("devise:install")
  environment 'config.action_mailer.default_url_options = { host: "localhost", port: 3000 }', env: 'development'
  generate("devise User")

  matcher = "class ApplicationController < ActionController::Base\n"
  inject_into_file("app/controllers/application_controller.rb", after: "#{matcher}") do
    <<~"RUBY"
      before_action :authenticate_user!
    RUBY
  end

  # Main site
  generate(:controller, "Home", "index")
  route "root to: 'home#index'"

  inject_into_file("app/controllers/home_controller.rb", after: "class HomeController < ApplicationController\n") do
    <<~"RUBY"
      skip_before_action :authenticate_user!
    RUBY
  end

  # Database
  rails_command("db:migrate")

  # Rubocop
  path = File.expand_path(File.dirname(__FILE__))
  file = File.open("#{path}/files/.rubocop.yml", "r+")
  run("echo #{file} >> .rubocop.yml")
  run("bundle exec rubocop -a")

  # Git
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit generated via BoilerplateCode.com' }
end
