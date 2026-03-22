#!/bin/bash

PLAYER="spotify"
STATUS=$(playerctl -p $PLAYER status 2>/dev/null)
CACHE_DIR="/tmp/waybar_lyrics"
mkdir -p "$CACHE_DIR"

if [ "$STATUS" = "Playing" ]; then
    ARTIST=$(playerctl -p $PLAYER metadata artist)
    TITLE=$(playerctl -p $PLAYER metadata title)
    POS=$(playerctl -p $PLAYER position)
    SONG_ID=$(echo "$ARTIST$TITLE" | md5sum | cut -d' ' -f1)
    LRC_FILE="$CACHE_DIR/$SONG_ID.lrc"

    if [ ! -f "$LRC_FILE" ]; then
        QUERY=$(echo "$TITLE $ARTIST" | jq -sRr @uri)
        curl -s "https://lrclib.net/api/search?q=$QUERY" | jq -r '.[0].syncedLyrics // empty' > "$LRC_FILE"
    fi
    
    if [ -s "$LRC_FILE" ]; then
        M=$(( ${POS%.*} / 60 ))
        S=$(( ${POS%.*} % 60 ))
        TIMESTAMP=$(printf "[%02d:%02d" $M $S)
        LYRIC=$(grep -E "^\[" "$LRC_FILE" | awk -v t="$TIMESTAMP" '$1 <= t' | tail -n 1 | sed 's/\[.*\] //')
        
        if [ -n "$LYRIC" ]; then
            MSG="$LYRIC"
        else
            MSG="$TITLE - $ARTIST"
        fi
    else
        MSG="$TITLE - $ARTIST"
    fi
else
    HOUR=$(date +%H)
    [ "$HOUR" -lt 12 ] && GREET="Good morning" || { [ "$HOUR" -lt 18 ] && GREET="Good afternoon" || GREET="Good Night"; }
    MSG="$GREET, iPPC"
fi

echo "{\"text\": \"$MSG\"}"
