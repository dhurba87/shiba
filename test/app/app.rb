require 'bundler'
Bundler.setup(:test)
require 'shiba'
require 'shiba/backtrace'
Shiba::Backtrace.ignore.delete('test')
require 'active_record'
require 'shiba/setup'

require_relative './models/organization'
require_relative './models/user'

if ENV['SHIBA_DEBUG']
  ActiveRecord::Base.logger = Logger.new('/dev/stdout')
end


database_yml = File.join(File.dirname(__FILE__), "..", "database.yml")
database_yml = database_yml + ".example" unless File.exist?(database_yml)

connection = YAML.load_file(database_yml)

ActiveRecord::Base.establish_connection(connection['mysql'])

org = Organization.create!(name: 'test')
org.users.create!(email: 'squirrel@example.com')

User.find_by(email: 'squirrel@example.com')