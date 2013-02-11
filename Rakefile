task :default => :spec

task :spec do
  ENV['DATABASE_URL'] = 'postgres://localhost/explainruby_test'
  exec *%w[bundle exec ruby spec/code_spec.rb --color]
end

task :environment do
  require 'bundler'
  Bundler.setup
  require 'app'
end

namespace :db do
  task :rebuild => :environment do
    DataMapper.auto_migrate!
  end

  task :migrate => :environment do
    DataMapper.auto_upgrade!
  end

  task :bootstrap => :environment do
    if ExplainRuby::Code.storage_exists?
      Rake::Task[:'db:migrate'].invoke
    else
      Rake::Task[:'db:rebuild'].invoke
    end
  end
end
