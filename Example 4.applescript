(*	===============================================================================

	Insert Example 4 for What's Tuned
	Based on template Version: 1.0
	(c)2017 Plauw
	
	This example shows how to:
	1/ Retrieve a snippet of the lyrics from LyricWikia API or MusixMatch API in formatted HTML string with
	a link to the website for the full lyrics.
	2/ return 'missing value' in GETARTISTINFO to fall back on the default artist info in What's Tuned
	
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

	(* remove comments (double dash) below for the source you would like to use*)
	set lyricsResults to getLyricsFromLyricWikia(title, artist, languageCode)
	--set lyricsResults to getLyricsFromMakeItPersonal(title, artist, languageCode)
	--set lyricsResults to getLyricsFromMusixMatch(title, artist, languageCode) -- You will need an api for this one
	set snippet to item 1 of lyricsResults
	
	if snippet is equal to "" then
		set htmlText to "
			<html>
    			<body>
					<b>Lyrics for '" & item 2 of lyricsResults & "' not found at " & item 2 of lyricsResults & "<b></br>
					<a href=\"http://www.google.com/search?as_q=" & artist & " - " & title & " - lyrics\">Google for more...</a>
				</body>
			</html>"
	else
		set snippet to replaceText(snippet, "[...]", "<a href=\"" & item 4 of lyricsResults & "\">[...]</a>") -- in case of a snippet (only)
		set htmlText to "
			<html>
    			<body>
					" & snippet & "</p>
					================</br>
					<b>" & title & "</b></br>
					by</br><i>" & artist & "</i></br>
				</body>
			</html>"
	end if
	return {htmlText, title, item 3 of lyricsResults, item 4 of lyricsResults}
end GETLYRICS

on GETARTISTINFO(media, title, artist, featArtist, albumName, languageCode, countryCode)
	-- By returning missing value, What's Tuned will fall back on the default code
	return missing value
end GETARTISTINFO

on GETARTWORK(media, title, artist, featArtist, albumName, languageCode, countryCode, suggestion)
	set imgData to do shell script "curl -s --get '" & suggestion & "'" as data without altering line endings
	return {imgData, "", "", ""}
end GETARTWORK



on getLyricsFromLyricWikia(title, artist, languageCode)
	set urlStr to "https://lyrics.wikia.com/api.php?func=getSong&fmt=xml\" --data-urlencode \"artist=" & artist & "\" --data-urlencode \"song=" & title
	set rawXMLData to do shell script "curl -s --get \"" & urlStr & "\"" without altering line endings
	set snippet to extractBetween(rawXMLData, "<lyrics>", "</lyrics>")
	set track_share_url to extractBetween(rawXMLData, "<url>", "</url>")
	if snippet = "Not found" then set snippet to ""
	set snippet to replaceText(snippet, "
", "</br>") -- replace "\n" by </br>
	return {snippet, title, "LyricWikia", track_share_url}
end getLyricsFromLyricWikia

on getLyricsFromMakeItPersonal(title, artist, languageCode)
	set urlStr to "https://makeitpersonal.co/lyrics/\" --data-urlencode \"artist=" & artist & "\" --data-urlencode \"title=" & title
	set theLyrics to do shell script "curl -s --get \"" & urlStr & "\"" without altering line endings
	if theLyrics = "Sorry, We don't have lyrics for this song yet." then set theLyrics to ""
	set theLyrics to replaceText(theLyrics, "
", "</br>") -- replace "\n" by </br>
	return {theLyrics, title, "makeitpersonal.co", "https://makeitpersonal.co/lyrics/?artist=" & artist & "&title=" & title}
end getLyricsFromMakeItPersonal

on getLyricsFromMusixMatch(title, artist, languageCode)
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

(*
on geLyricsFromAZLyrics(title, artist, languageCode)
	set artist to replaceText(artist, " ", "")
	set title to replaceText(title, " ", "")
	set artist to toLowerCase(artist)
	set title to toLowerCase(title)
	set url_webpage to "http://www.azlyrics.com/lyrics/" & artist & "/" & title & ".html"
	set lyrics to scrapeWebPage(url_webpage, "<div class=\"lyricsh\">", "<!-- MxM banner -->")
	return {lyrics, title & " by " & artist, "AZLyrics", url_webpage}
end geLyricsFromAZLyrics
*)


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
	
	set userAgentString to "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5"
	set htmlText to do shell script "curl -A '" & userAgentString & "' -L -s --get '" & urlStr & "'" without altering line endings
	return extractBetween(htmlText, startText, endText)
end scrapeWebPage

on toLowerCase(theText)
	set upperCaseChars to "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	set lowerCaseChars to "abcdefghijklmnopqrstuvwxyz"
	set theChars to characters of theText
	repeat with c in theChars
		if c is in upperCaseChars then set contents of c to item (offset of c in upperCaseChars) of lowerCaseChars
	end repeat
	return theChars as string
end toLowerCase

