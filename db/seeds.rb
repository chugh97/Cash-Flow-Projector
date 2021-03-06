# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

TransactionFrequency.create!(:name => 'Daily')
TransactionFrequency.create!(:name => 'Weekly')
TransactionFrequency.create!(:name => 'Monthly')
TransactionFrequency.create!(:name => 'Annualy')

#Create a sample user for tests to use
User.create!(:email => 'test_user@cashflowprojector.com', :password => SecureRandom.hex(8))
