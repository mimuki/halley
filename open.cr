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
	context = get_context url
	if !context
		# Sometimes the url we have is the one to the AP object and not
		# the mastodon-specific one, so we need a level of indirection
		# to get it
		res = HTTP::Client.get url
		if res.status_code == 302
			u = URI.parse url
			location = res.headers["location"]
			url = "#{u.scheme}://#{u.host}/#{location}"
			context = get_context url
		end
	end

	if !context
		puts "Couldn't find match for #{url}"
		Process.exec("xdg-open #{url}", shell: true)
	end

	c = JSON.parse(context.body)
	if !c.as_h?
		puts "Couldn't find match for #{url}"
		Process.exec("xdg-open #{url}", shell: true)
	end
	c["ancestors"].as_a.each {|status| display status}
	puts status
	c["descendants"].as_a.each {|status| display status}
end

def display(status : JSON::Any)
	author = status["account"].as_h
	name = author["display_name"].as_s

	id = author["acct"].as_s
	if !id.matches?(/\@/)
		u = URI.parse author["url"].as_s
		id = "#{id}@#{u.host}"
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

def get_context(url : String)
	pattern = /.*\/(.+)$/

	u = URI.parse url
	if !u.scheme || !u.host
		return
	end
	base = "#{u.scheme}://#{u.host}"

	if m = url.match(pattern)
		id = m[1]
	end

	if !base || !id
		return
	end

	context_url = "#{base}/api/v1/statuses/#{id}/context"
	context = HTTP::Client.get context_url
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
		exit
	elsif context.status_code != 200
		return
	end

	return context
end
