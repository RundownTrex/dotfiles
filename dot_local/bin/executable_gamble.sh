#!/bin/bash
# ~/.local/bin/dice-coin
GAME=$(echo -e "Roll Dice\nFlip Coin\nRandom Number\nMagic 8-Ball" | rofi -dmenu -p "Choose game:")

case "$GAME" in
    "Roll Dice")
        SIDES=$(echo -e "6\n20\n12\n10\n8\n4" | rofi -dmenu -p "How many sides?")
        RESULT=$((RANDOM % SIDES + 1))
        notify-send -i games-dice "Dice Roll" "🎲 You rolled a $RESULT (1-$SIDES)"
        ;;
    "Flip Coin")
        RESULT=$((RANDOM % 2))
        if [ $RESULT -eq 0 ]; then
            notify-send -i money "Coin Flip" "🪙 HEADS"
        else
            notify-send -i money "Coin Flip" "🪙 TAILS"
        fi
        ;;
    "Random Number")
        MAX=$(rofi -dmenu -p "Maximum number (1 to ?):")
        if [[ "$MAX" =~ ^[0-9]+$ ]]; then
            RESULT=$((RANDOM % MAX + 1))
            notify-send -i calculator "Random Number" "🔢 Your number: $RESULT (1-$MAX)"
        fi
        ;;
    "Magic 8-Ball")
        ANSWERS=("Yes" "No" "Maybe" "Ask again later" "Definitely" "Not likely" "Absolutely" "Don't count on it" "Signs point to yes" "Very doubtful")
        ANSWER=${ANSWERS[$RANDOM % ${#ANSWERS[@]}]}
        notify-send -i crystal-ball "Magic 8-Ball" "🔮 $ANSWER"
        ;;
esac
