(*	===============================================================================

	Insert Example 3 for What's Tuned
	Based on template Version: 1.0
	(c)2017 Plauw
	
	This example show how to:
	1/ download matching artwork (from Spotify or iTunes Store)
	
	This example ommits the other 2 functions (GETLYRICS and GETARTISTINFO) and
	only shows fullsized albumb cover artwork. For Lyrics and artist info, this script 
	will fall back on the default sources in What's Tuned.
	
	Note that it's essential to add 'as data' and 'without altering line endings' to
	the do shell script command below. This is needed to pass the unaltered binary data 
	from the shell back to the script.
	
	Note that you will need JSONHelper application (get it from from the App Store)
*)

on GETARTWORK(media, title, artist, featArtist, albumName, languageCode, countryCode, suggestion)
	set imgData to do shell script "curl -s --get '" & suggestion & "'" as data without altering line endings
	return {imgData, "", "", ""}
end GETARTWORK
