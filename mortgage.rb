#!/usr/bin/ruby

require 'optparse'
require 'fileutils'

# mortgage calculations
years=15
price=200000
down=20.0
hoa=300
tax=0.01
fees=true

interest=0.035
if years === 15
	interest=0.0315
elsif years === 30
	interest=0.0392
end

OptionParser.new do |opt|
  opt.on('-y', '--years YEARS') { |o| years = o.to_i }
  opt.on('-p', '--price PRICE') { |o| price = o.to_i }
  opt.on('-d', '--down DOWN') { |o| down = o.to_f }
  opt.on('-h', '--hoa HOA') { |o| hoa = o.to_i }
  opt.on('-t', '--tax TAX') { |o| tax = o.to_f }
  opt.on('-i', '--interest INTEREST') { |o| interest = o.to_f }
  opt.on('-n', '--no-fees') { fees = false}
end.parse!

down = price * down / 100
mortgage=price-down

# file to write
filename = "results/#{price}-price/#{down.round}-down/#{years}-years/fees-#{fees}.csv"
FileUtils.mkdir_p "results/#{price}-price/#{down.round}-down/#{years}-years"
file = File.open("results/#{price}-price/#{down.round}-down/#{years}-years/fees-#{fees}.csv", 'w')
puts "Writing results to: results/#{price}-price/#{down.round}-down/#{years}-years/fees-#{fees}.csv"

monthly_interest=interest/12

payment=1876.61
left=mortgage
interest_owed=0
total_lost=0

#figure out payment
percent_kept = 1 + monthly_interest
for i in 1..(years * 12 - 1)
	percent_kept /= 1 + monthly_interest
end
payment = (monthly_interest * mortgage) / (1 - percent_kept)
if fees === true
	puts "	Monthly Payment: #{(payment + hoa + (tax * price / 12)).round(2)}"
else
	puts "	Monthly Payment: #{payment.round(2)}"
end

file.puts "month,lost to interest,lost to all fees,average loss per month,total lost,mortgage left"
# Calculations
for year in 1..years
	break if left.round <= 0

	for month in 1..12
		break if left.round <= 0

		interest_lost = left * (1 + monthly_interest) - left
		interest_owed += interest_lost
		if fees === true
			lost = interest_lost + hoa + (tax * price / 12)
			total_lost += lost
		else
			lost = interest_lost
			total_lost = interest_owed
		end
		left = left * (1 + monthly_interest) - payment
		file.puts "#{month}/#{year},#{interest_lost.round(2)},#{lost.round(2)},#{(total_lost / ((year - 1) * 12 + month)).round(2)},#{total_lost.round(2)},#{left.round(2)}"
	end
end

puts "	Total lost: #{total_lost.round(2)}"
puts "	Interest per month on average: #{(interest_owed / (year * 12)).round(2)}"
puts "	Fees per month on average: #{(total_lost / (year * 12)).round(2)}"
puts "	Total owed: #{(total_lost + left).round(2)}"

file.close
`open #{filename}`
