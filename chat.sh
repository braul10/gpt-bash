#!/bin/bash

MODEL="gpt-4o"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(cat "$SCRIPT_DIR/.env" | xargs)
fi

if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: Please set the OPENAI_API_KEY environment variable."
    exit 1
fi

query_gpt() {
    local text_query="$1"

    local prompt=$(jq -n --arg text_query "$text_query" \
    '[
        {"role": "system", "content": "You are a helpful assistant who gives specific and short answers when possible."},
        {"role": "user", "content": $text_query}
    ]')

    local response=$(curl -s -w "\n%{http_code}" -X POST https://api.openai.com/v1/chat/completions \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
          "model": "'"$MODEL"'",
          "messages": '"$prompt"'
        }')

    local body=$(echo "$response" | sed '$d')
    local status_code=$(echo "$response" | tail -n1)

    if [ "$status_code" -ne 200 ]; then
        echo -e "$(colored "Error: Received status code $status_code" red)"
        echo -e "$(colored "Response: $body" red)"
        exit 1
    fi

    echo "$body" | jq -r '.choices[0].message.content'
}

colored() {
    local text="$1"
    local color="$2"

    case "$color" in
        red)
            echo -e "\033[31m$text\033[0m"
            ;;
        green)
            echo -e "\033[32m$text\033[0m"
            ;;
        blue)
            echo -e "\033[34m$text\033[0m"
            ;;
        *)
            echo "$text"
            ;;
    esac
}

colored "
 ██████╗ ██████╗ ████████╗
██╔════╝ ██╔══██╗╚══██╔══╝
██║  ███╗██████╔╝   ██║   
██║   ██║██╔═══╝    ██║   
╚██████╔╝██║        ██║   
 ╚═════╝ ╚═╝        ╚═╝   
Model: $MODEL
" red

while true; do
    read -p "$(colored 'User > ' green)" user_input

    if [[ "$user_input" == "exit" || "$user_input" == "e" ]]; then
        break
    fi

    response=$(query_gpt "$user_input")
    colored "GPT > $response" blue
done
