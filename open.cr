require "http/client"
require "json"
require "file_utils"

ACCOUNTS_DIR = Path["~/.config/msync/msync_accounts/"].expand(home: true)

Dir.open(ACCOUNTS_DIR).each_child do |child|
	File.open(ACCOUNTS_DIR / child / "home.list") do |file|
		while status = file.gets("--------------\n")
			if m = status.match(/status id: #{ARGV[0]}\nurl: (.*)/)
				url = m[1]
				process url, status
			end
		end
	end
end

def process(url : String, status : String)
	m = url.match(/(https:\/\/[^\/]+)\/.*\/([0-9]+).*/)
	if !m
		puts "Couldn't match host and id"
		exit
	end

	host = m[1]
	id = m[2]

	context = HTTP::Client.get "#{host}/api/v1/statuses/#{id}/context"
	if context.status_code == 401
		# Can't do it on origin instance, do it on our instance

		Process.run("msync queue context #{ARGV[0]}", shell: true)
		Process.run("msync sync -m 3", shell: true)
		Dir.open(ACCOUNTS_DIR).each_child do |child|
			filename = ACCOUNTS_DIR / child / "fetched" / "#{ARGV[0]}.list"
			if File.exists?(filename)
				File.open(filename) do |file|
					IO.copy file, STDOUT
				end
			end
		end
		return
	end
	if context.status_code != 200
		# Really can't do anything, fallback to outside handler
		Process.exec("xdg-open #{url}", shell: true)
	end

	c = JSON.parse(context.body)
	c["ancestors"].as_a.each {|status| display host, status}
	puts status
	c["descendants"].as_a.each {|status| display host, status}
end

def display(host : String, status : JSON::Any)
	author = status["account"].as_h
	name = author["display_name"].as_s

	id = author["acct"].as_s
	if !id.matches?(/\@/)
		domain = host.gsub(/https:\/\//, "")
		id = "#{id}@#{domain}"
	end
	id = "@#{id}"

	puts "url: #{status["url"]}"
	puts "author: #{name} (#{id})"

	io = IO::Memory.new
	Process.run("w3m -dump -T text/html", output: io, shell: true) do |process|
		process.input << status["content"].as_s
		process.input.flush
	end

	print "body: "
	puts io.to_s.strip

	puts "visibility: #{status["visibility"]}"

	date = status["edited_at"]
	if date.to_s == ""
		date = status["created_at"]
	end
	puts "Posted on: #{date.to_s}"
	
	favs = status["favourites_count"].as_i
	boosts = status["reblogs_count"].as_i
	replies = status["replies_count"].as_i
	puts "#{favs} favs | #{boosts} boosts | #{replies} replies"
	puts "--------------\n"
end
