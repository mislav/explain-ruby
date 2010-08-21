multitask :default => :spec # [:server, :livereload]

task :server do
  exec 'bundle', 'exec', 'shotgun'
end

task :livereload do
  exec 'livereload'
end

task :spec do
  exec *%w[bundle exec ruby code.rb --color]
end