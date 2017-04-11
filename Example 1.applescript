(*	===============================================================================

	Insert Example 1 for What's Tuned
	Based on template Version: 1.0
	(c)2017 Plauw
	
	This example shows how to get information from LyricWikia, Wikipedia and any url for fetching artwork
	Its output is formatted the same way as the default output in What's Tuned. Therfore, this example
	can be considred as a tutorial and only provide artwork (from Spotify and iTunesStore) additional
	to what What's Tuned does by default.
	
	Note that this script is a pure text file (.applescript). You may want to save it as a compiled apple script
	(.scpt) for better performance.
*)


(*	===============================================================================
	Main run handler (for testing from within Script Editor ONLY).
	Use this for testing your Inserts from the "Script Editor.app". 
	This run handler will NEVER be called by What's Tuned.
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
	set snippet to item 1 of LyricWikiaResults
	log (snippet)
	if snippet is equal to "" then
		set htmlText to "
			<html>
    				<body>
					Lyrics for this song were not found at LyricWikia.</p>
					<a href=\"" & item 4 of LyricWikiaResults & "\">Create these lyrics at LyricWika.com...</a></p>
					<a href=\"http://www.google.com/search?as_q=" & artist & " - " & title & " - lyrics\">Google for more lyrics...</a>
				</body>
			</html>"
	else
		set htmlText to "
			<html>
    				<body>
					Lyrics found!</p>
					<a href=\"" & item 4 of LyricWikiaResults & "\">View these lyrics at LyricWikia...</a>
				</body>
			</html>"
	end if
	return {htmlText, title, item 3 of LyricWikiaResults, item 4 of LyricWikiaResults}
end GETLYRICS

on GETARTISTINFO(media, title, artist, featArtist, albumName, languageCode, countryCode)
	set wikiPediaResults to getWikiPageExtractForArtist(artist, languageCode)
	set extract to item 1 of wikiPediaResults
	if extract is equal to "" then
		set htmlText to "
			<html>
    				<body>
					Nothing found on Wikipedia for '" & artist & "'.</p>
					<a href=\"http://www.google.com/search?as_q=" & artist & "\">Google for more...</a>
				</body>
			</html>"
	else
		set htmlText to "
			<html>
    				<body>
					" & extract & "</p>
					<a href=\"" & item 4 of wikiPediaResults & "\">Source: " & item 3 of wikiPediaResults & "</a></p>
					<a href=\"http://www.google.com/search?as_q=" & artist & "\">Google for more on '" & artist & "'...</a>
				</body>
			</html>"
	end if
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

on getWikiPageExtractForArtist(artist, languageCode)
	-- Note: we cannot use 'fetch JSON from' here because ther may be char's like '&' in the artist name. 
	-- JSON helper seems not to deal with this.
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

