#!/bin/bash
# ~/.local/bin/random-joke
JOKE=$(curl -s "https://official-joke-api.appspot.com/random_joke" 2>/dev/null | jq -r '"\(.setup)\n\n\(.punchline)"')
if [ -n "$JOKE" ]; then
    notify-send -i face-laugh "Random Joke 😄" "$JOKE"
else
    # Fallback offline jokes
    JOKES=(
        "Why do programmers prefer dark mode?\nBecause light attracts bugs! 🐛"
        "How many programmers does it take to change a light bulb?\nNone. That's a hardware problem! 💡"
        "Why do Java developers wear glasses?\nBecause they can't C#! 👓"
        "What's a programmer's favorite hangout place?\nFoo Bar! 🍺"
    )
    JOKE=${JOKES[$RANDOM % ${#JOKES[@]}]}
    notify-send -i face-laugh "Random Joke 😄" "$JOKE"
fi
