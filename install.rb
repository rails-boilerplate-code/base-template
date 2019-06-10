gem "stripe"
gem "devise"
gem_group :development, :test do
  gem "dotenv-rails"
end

after_bundle do

  # ENV variables setup
  run("touch .env")
  run("echo .env >> .gitignore")

  puts "\n==============================================================================="
  puts "\nFor details on how to find these keys go here:"
  puts "\nhttps://github.com/rails-boilerplate-code/base-template/blob/master/README.md\n\n"
  stripe_test_secret_key = ask("What is your Stripe Test Secret Key?")
  stripe_test_publish_key = ask("What is your Stripe Test Publishable Key?")
  run("echo 'STRIPE_SECRET_KEY=#{stripe_test_secret_key}' >> .env")
  run("echo 'STRIPE_PUBLISHABLE_KEY=#{stripe_test_publish_key}' >> .env")
  puts "\n===============================================================================\n\n"

  # DotEnv Gem setup
  run("echo 'Dotenv::Railtie.load' >> config/application.rb")

  # Stripe payments
  initializer 'stripe.rb', <<-CODE
    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
  CODE

  # Devise authentication
  generate("devise:install")
  environment 'config.action_mailer.default_url_options = { host: "localhost", port: 3000 }', env: 'development'
  generate("devise User")

  # Main site
  generate(:controller, "Home", "index")
  route "root to: 'home#index'"

  # Database
  rails_command("db:migrate")

  # Git
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit generated via BoilerplateCode.com' }
end
