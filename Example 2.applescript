(*	===============================================================================

	Insert Example 2 for What's Tuned
	Based on template Version: 1.0
	(c)2017 Plauw
	
	This example show how to:
	1/ Build a list of url's formatted in a HTML string that link to webpages containing lyrics
	2/ Show artist info from Wikipedia + picture of artist and link from/to Spotify
	
	Note that you will need JSONHelper application (get it from from the App Store)
*)


(*	===============================================================================
	Main run handler. (for testing from within Script Editor ONLY)
	Use this for testing your Inserts from the "Script Editor.app". This run handler will NEVER be called by What's Tuned.
*)
on run
	(* Set variables we use for testing. *)
	set media to "iTunes"
	set title to "Hello"
	set artist to "Adele"
	set featArtist to ""
	set languageCode to "nl"
	set countryCode to "gb"
	set albumName to "25"
	set suggestion to "https://lh6.googleusercontent.com/nDSnomKmhWoqM23Y8bqX9ZzIvhghMxDmEwMyiPabtt8i9FGYrb4hoPvc-qP9ottlnyvcjpDxRQ=w300"
	
	(* remove comments (double dash) below for the line you want to test*)
	set result to GETLYRICS(media, title, artist, featArtist, albumName, languageCode, countryCode)
	--set result to GETARTISTINFO(media, title, artist, featArtist, albumName, languageCode, countryCode)
	--set result to GETARTWORK(media, title, artist, featAsrtist, albumName, languageCode, countryCode, suggestion)
end run



on GETLYRICS(media, title, artist, featArtist, albumName, languageCode, countryCode)
	set LyricWikiaResults to getLyricsFromLyricWikia(title, artist, languageCode)
	set makeItPersonalResults to getLyricsFromMakeItPersonal(title, artist, languageCode)
	set musixMatchResults to getURLFromMusixMatch(title, artist, languageCode)
	set htmlText to "
			<html>
    				<body>
				<b>" & title & "</b></br>
				by</br><i>" & artist & "</i></br>
				================</p>
					<a href=\"" & item 4 of LyricWikiaResults & "\">View these lyrics at LyricWikia...</a></br>
					<a href=\"" & item 4 of makeItPersonalResults & "\">View these lyrics at makeitpersonal.co...</a></br>
					<a href=\"" & item 4 of musixMatchResults & "\">View these lyrics at MusixMatch...</a></br>
					<a href=\"http://www.google.com/search?as_q=" & artist & " - " & title & " - lyrics\">Google for more...</a>
				</body>
			</html>"
	return {htmlText, title, item 3 of LyricWikiaResults, item 4 of LyricWikiaResults}
end GETLYRICS

on GETARTISTINFO(media, title, artist, featArtist, albumName, languageCode, countryCode)
	
	-- 1/ Get info from Wikipedia
	set wikiPediaResults to getWikiPageExtractForArtist(artist, languageCode)
	if item 1 of wikiPediaResults is equal to "" then
		set extract to "Not found"
	else
		set extract to item 1 of wikiPediaResults
	end if
	
	-- 2/ Get artist info (image url) from Spotify
	set spotifyResult to getSpotifyInfoForArtist(artist)
	
	-- 3/ Format this info in a HTML string
	set htmlText to "
		<html>
			<head>
				<style> body { color: black; font-family: Comic Sans MS; font-size: 14px;}
				</style>
			</head>
    			<body>
				<center>
					<img src=\"" & item 1 of spotifyResult & "\"></br>
					<a href=\"" & item 2 of spotifyResult & "\">View artist in Spotify...</a></p>
				</center>
				" & extract & "</p>
				<a href=\"" & item 4 of wikiPediaResults & "\">read more about '" & artist & "' on wikipedia...</a></br>
			</body>
		</html>"
	return {htmlText, item 2 of wikiPediaResults, item 3 of wikiPediaResults, item 4 of wikiPediaResults}
end GETARTISTINFO

on GETARTWORK(media, title, artist, featArtist, albumName, languageCode, countryCode, suggestion)
	set imgData to do shell script "curl -s --get '" & suggestion & "'" as data without altering line endings
	return {imgData, "", "", ""}
end GETARTWORK



on getLyricsFromLyricWikia(title, artist, languageCode)
	set urlStr to "https://lyrics.wikia.com/api.php?func=getSong&fmt=xml\" --data-urlencode \"artist=" & artist & "\" --data-urlencode \"song=" & title
	set rawXMLData to do shell script "curl -s --get \"" & urlStr & "\""
	set snippet to extractBetween(rawXMLData, "<lyrics>", "</lyrics>")
	set track_share_url to extractBetween(rawXMLData, "<url>", "</url>")
	if snippet = "Not found" then set snippet to ""
	return {snippet, title, "LyricWikia", track_share_url}
end getLyricsFromLyricWikia

on getLyricsFromMakeItPersonal(title, artist, languageCode)
	set urlStr to "https://makeitpersonal.co/lyrics/\" --data-urlencode \"artist=" & artist & "\" --data-urlencode \"title=" & title
	set theLyrics to do shell script "curl -s --get \"" & urlStr & "\""
	if theLyrics = "Sorry, We don't have lyrics for this song yet." then set theLyrics to ""
	set theLyrics to replaceText(theLyrics, "
", "</br>")
	return {theLyrics, title, "makeitpersonal.co", "https://makeitpersonal.co/lyrics/?artist=" & artist & "&title=" & title}
end getLyricsFromMakeItPersonal

on getURLFromMusixMatch(title, artist, languageCode)
	(* 	There no way to search MusixMatch even if you just want to return a link to their website :(
		Here below, you will find a 'best try' to guess the webpage for the lyrics. This will work in many cases. 
		If you get a developer API key, you can use the function: getLyricsFromMusixMatch
	*)
	set artist to replaceText(artist, " ", "-")
	set title to replaceText(title, " ", "-")
	set track_share_url to "https://www.musixmatch.com/lyrics/" & artist & "/" & title
	return {"Found", title & " by " & artist, "MusixMatch", track_share_url}
end getURLFromMusixMatch

on getLyricsFromMusixMatch(title, artist, languageCode, api_key)
	set MUSIXMATCH_APIKEY to "PUT YOUR MUSIXMATH API KEY HERE..."
	set urlStr to "http://api.musixmatch.com/ws/1.1/track.search?format=json&page_size=5&apikey=" & MUSIXMATCH_APIKEY & "&q_artist=" & artist & "&q_track=" & title
	tell application "JSON Helper"
		try
			set JSONResult to fetch JSON from urlStr with cleaning feed
			set availableFlag to available of header of message of JSONResult
			if availableFlag = "0" then return {"", title, "MusixMatch", ""}
			set track_list to track_list of body of message of JSONResult
			set firstTrack to track of first item of track_list
			set track_share_url to track_share_url of firstTrack
		on error
			return {"", "ERROR!", "MusixMatch (failed).", "www.musixmatch.com"}
		end try
	end tell
	set track_share_url to track_share_url & "/translation/" & languageCode
	return {theLyrics, title & " by " & artist, "MusixMatch", track_share_url}
end getLyricsFromMusixMatch


on getWikiPageExtractForArtist(artist, languageCode)
	-- Note: we can not use fetch JSON from here because ther may be char's like '&' 
	-- in the artist name. JSON helper seems not to deal with this.
	set urlStr to "https://" & languageCode & ".wikipedia.org/w/api.php?action=query&prop=extracts&format=json&formatversion=2&exintro&redirects\" --data-urlencode \"&titles=" & artist
	set rawJSONData to do shell script "curl -s --get \"" & urlStr & "\""
	tell application "JSON Helper"
		set JSONResult to read JSON from rawJSONData
		set WikiPages to pages of query of JSONResult
		set WikiPage to first item of WikiPages
		try
			set snippet to extract of WikiPage
			set pageid to pageid of WikiPage
			set titleWikiPedia to title of WikiPage
		on error
			return {"", artist, languageCode & ".wikipedia.org", "https://" & languageCode & ".wikipedia.org"}
		end try
	end tell
	
	return {snippet, titleWikiPedia, languageCode & ".wikipedia.org", "https://" & languageCode & ".wikipedia.org/wiki?curid=" & pageid}
end getWikiPageExtractForArtist

on getSpotifyInfoForArtist(artist)
	set urlStr to "https://api.spotify.com/v1/search?q=" & artist & "&type=artist"
	log (urlStr)
	tell application "JSON Helper"
		try
			set JSONResult to fetch JSON from urlStr with cleaning feed
			set spotifyUri to uri of first item of |items| of artists of JSONResult as string
			
			set imgList to images of first item of |items| of artists of JSONResult as list
			set imgUrl to ""
			repeat with imgItem in imgList
				if width of imgItem as integer ² 400 and imgUrl = "" then
					set imgUrl to |url| of imgItem
				end if
			end repeat
		on error
			return {"", artist, "Spotify", ""}
		end try
	end tell
	return {imgUrl, artist, "Spotify", spotifyUri}
end getSpotifyInfoForArtist


(* Some helpers functions
*)
on replaceText(someText, findString, replaceString)
	set currentTIDs to text item delimiters of AppleScript
	set text item delimiters of AppleScript to findString
	set listOfTextItem to text items of someText
	set text item delimiters of AppleScript to replaceString
	set resultText to listOfTextItem as string
	set text item delimiters of AppleScript to currentTIDs
	return resultText
end replaceText

on extractBetween(someText, startText, endText)
	set startOffset to offset of startText in someText
	set endOffset to offset of endText in someText
	set startOffset to startOffset + (length of startText)
	set endOffset to endOffset - 1
	set finaltext to text startOffset thru endOffset of someText
	return finaltext
end extractBetween

on scrapeWebPage(urlStr, startText, endText)
	set htmlText to do shell script "curl -L -s --get '" & urlStr & "'" without altering line endings
	return extractBetween(htmlText, startText, endText)
end scrapeWebPage

