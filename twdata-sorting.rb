#!/usr/bin/ruby

require 'json'
require 'optparse'
require 'erb'
require 'date'

TEMPLATE = <<'EOF'
<html>
  <head>
    <title>Sorted Tweets</title>
    <style>
.tweet_text {
  white-space: pre-wrap;
}
    </style>
  </head>
  <body>
    <table>
      <thead>
        <tr><th>Text</th><th>Status</th><th>RTs</th><th>Favs</th><th>At</th></tr>
      </thead>
      <tbody>
% tweets_chunk.each do |tweet|
        <tr><td class="tweet_text"><%= expand_fulltext(tweet) %></td><td><a href="https://twitter.com/<%= screen_name %>/status/<%= tweet["id"] %>"><%= tweet["id"] %></a></td><td><%= tweet["retweet_count"] %></td><td><%= tweet["favorite_count"] %></td><td><%= tweet["created_at"] %></td></tr>
%   if tweet["entities"] && tweet["entities"]["media"] && !tweet["entities"]["media"].empty?
      <tr>
%     tweet["entities"]["media"].each do |media|
%       fx = File.extname(media["media_url"].sub(%r:.*/:, ""))
%       if %w:webm mp4 mkv:.include?(fx)
          <td colspan="4"><video controls="controls"><source src="file:///<%= Dir.pwd.sub(%r:^/:, "") %>/tweet_media/<%= tweet["id"] %>-<%= media["media_url"].sub(%r:.*/:, "") %>" type="video/<%= fx %>"/></source></video></td>
%       else
          <td colspan="4"><img src="file:///<%= Dir.pwd.sub(%r:^/:, "") %>/tweet_media/<%= tweet["id"] %>-<%= media["media_url"].sub(%r:.*/:, "") %>" style="max-height: 300px;"/></td>
%       end
%     end
      </tr>
%   end
% end
      </tbody>
    </table>
  </body>
</html>
EOF

def expand_fulltext(tweet)
  if tweet["entities"]["urls"] && !tweet["entities"]["urls"].empty?
    text = tweet["full_text"]
    tweet["entities"]["urls"].each do |url|
      text = text.sub(url["url"], sprintf('<a href="%s">%s</a>', url["expended_url"], url["display_url"]))
    end
    text
  else
    tweet["full_text"]
  end
end

opt = OptionParser.new

mode = :time
limit = 0
only_from = nil
non_reply = nil
non_rt = nil
split_by = 300
headnum = nil
require_media = false
outdir = "."
html_template = nil

opt.on("-r [retweets]") {|v|
  mode = :rt
  limit = v.to_i if v
}
opt.on("-f [favorites]") {|v|
  mode = :fv
  limit = v.to_i if v
}
opt.on("-m") {|v| require_media = true }
opt.on("-M") { non_reply = true }
opt.on("-R") { non_rt = true }
opt.on("-s split_count") {|v| split_by = v }
opt.on("-t count") {|v| headnum = v.to_i}
opt.on("-o outdir") {|v| outdir = v }
opt.on("-h template") {|v| html_template = File.read(v) }

opt.parse!(ARGV)

account = File.read("account.js").sub(/\A.*? = /, "") 
account = JSON.load(account)
screen_name = account[0]["account"]["username"]

twdata = File.read("tweet.js").sub(/\A.*? = /, "")
tweets = JSON.load(twdata)

if mode == :rt && limit > 0
  tweets.delete_if {|i| i["retweet_count"].to_i <= limit }
end
if mode == :fv && limit > 0
  tweets.delete_if {|i| i["favorite_count"].to_i <= limit }
end
tweets.delete_if {|i| !(i["entities"] && i["entities"]["media"] && !i["entities"]["media"].empty?) } if require_media
tweets.delete_if {|i| i["full_text"] =~ /\ART @[a-zA-Z0-9_]+:/ && !i["entities"]["user_mentions"].empty? } if non_rt
tweets.delete_if {|i| i["in_reply_to_user_id"] && !i["in_reply_to_user_id"].empty? } if non_reply

tweets.sort_by! {|i| i["retweet_count"].to_i }.reverse! if mode == :rt
tweets.sort_by! {|i| i["retweet_count"].to_i }.reverse! if mode == :fv

if headnum
  tweets = tweets[0, headnum]
end

split_by = tweets.length if split_by < 1

0.upto(tweets.length / split_by) do |split_num|
  break if split_num * split_by >= tweets.length
  tweets_chunk = tweets[(split_num * split_by), split_by]
  File.open(File.join(outdir, "TweetChunk_#{sprintf('%05d', split_num)}.html"), "w") do |f|
    erb = ERB.new((html_template || TEMPLATE), trim_mode: "%")
    f.puts erb.result(binding)
  end
end