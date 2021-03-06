# Twdata Analyzer

Utils for analyze and format "Twitter Data" archive.

## Require 

* Ruby \>2.3

## twdata-sorting.rb

Create tweets listed HTML with sorting.

### Usage

* Install `twdata-sorting.rb` to where you want.
* `cd` to expanded Twitter Data archive directory. (include `tweet.js` and `tweet_media`)
* Run script

```
twdata-sorting.rb [options]
```

This script outs `TweetChunk_NNNNN.html` files.

### Options

|Option|Argument|Description|
|---|-------|--------------------------------------|
|`-r`|Retweet count (optional)|Sort desc by retweet count (and filter min retweets)|
|`-f`|Favorite count (optional)|Sort desc by favorite count (and filter min favorites)|
|`-m`||Only tweets include media|
|`-M`||Exclude reply|
|`-R`||Exclude retweet|
|`-s`|Split count|Count of tweets par file (default 300.) If less than `1` given, don't split.|
|`-t`|Tweet count|Out only top n tweets|
|`-o`|Directory|Use specify output directory|
|`-h`|Template file|Use specify eRuby template file|

### Example

```bash
twdata-sorting.rb -r 10 -M -t 100
```

* Sort by retweet.
* Filter tweet have retweet count less than 10.
* Exclude reply.
* 100 tweets per out file.