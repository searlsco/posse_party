# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

Rails.application.load_tasks

unless Rails.env.production?
  task "standardjs:fix" do
    unless system "yarn run standard:fix"
      fail "Standard JS failed"
    end
  end

  require "standard/rake"
  task :default do
    ENV["CI"] = "true"
    puts "--> rake standard:fix"
    Rake::Task["standard:fix"].invoke
    puts "--> rake standardjs:fix"
    Rake::Task["standardjs:fix"].invoke
    puts "--> rake test"
    Rake::Task["test"].invoke
    puts "--> rake test:system"
    Rake::Task["test:system"].invoke
  end
end
