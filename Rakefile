
task :compile do
  cd 'ext/' do
    sh 'ruby extconf.rb'
    sh 'make'
  end
end

task :test do
  sh 'rspec spec -r ./spec/spec_helpers.rb'
end

task :default => [:compile, :test]


