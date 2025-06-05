#!/bin/bash

# Get script directory for proper image paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIN_IMAGE="$SCRIPT_DIR/win_image.png"
LOSE_IMAGE="$SCRIPT_DIR/lose_image.png"

maze1=(
    "####################"
    "#....$........♥....#"
    "#.##############..#"
    "#$..#..........#..#"
    "#.#.##########.#..#"
    "#.#.E..........#..#"
    "#.#############...#"
    "#$................#."
    "#.##############.#."
    "#.#.............#.#"
    "#.#.#############.#"
    "#.#.............#.#"
    "#.###############.#"
    "#...............#.#"
    "#############.#.#.#"
    "#.............$...#"
    "#.###############.#"
    "#.................#"
    "#.###############.#"
    "P.................."
)

maze2=(
    "####################"
    "#........#.........#"
    "#.######.#.######..#"
    "#.#......#......#..#"
    "#.#.#########..#.$.#"
    "#.#.......E##..#...#"
    "#.#.#######....#####"
    "#.#...............##"
    "######.##########.##"
    "#.$.........$.....#"
    "#.#.#############.#"
    "#.#.............#.#"
    "#.#####.#####.#####"
    "#.....#.....#.....#"
    "###.#######.#####.#"
    "#.............#...#"
    "#.###############.#"
    "#.................#"
    "#.#####.#####.#####"
    "P.................."
)

maze3=(
    "####################"
    "#..........$.......#"
    "#.################.#"
    "#.#....#........E#.#"
    "#.###..###.######..#"
    "#.#$...#...##.#.#..#"
    "#.#.#.##.##.#.#....#"
    "#.#.#.#..####...$..#"
    "#.#.#.#.#...#.#.#..#"
    "#.#.#.#.#.#.#.#.#..#"
    "#.#.#.#.#.#.#.#.#..#"
    "#.#.#.#...#.#.#.#..#"
    "#.#.#.#####.#.#.#..#"
    "#.#.#.......#.#.#..#"
    "#.#.###########.#..#"
    "#.#........$....#..#"
    "#.################.#"
    "#......$...........#"
    "#.##################"
    "P.................."
)

player_name=""
current_level=1
attempt=1
current_score=0
declare -A best_times=( [1]=0 [2]=0 [3]=0 )
declare -a level_times
current_start_time=0

per_level_file="maze_level_scores.txt"
overall_file="maze_overall_scores.txt"

# Track collected rewards
declare -A collected_rewards
start_row=0
start_col=0

load_level_scores() {
    if [[ -f "$per_level_file" ]]; then
        while IFS=',' read -r name level hs_time; do
            if [[ "$name" == "$player_name" ]]; then
                best_times[$level]=$hs_time
            fi
        done < "$per_level_file"
    fi
}

save_level_score() {
    local level=$1
    local elapsed=$2
    local temp_file=$(mktemp)
    local updated=false
    
    if [[ ${best_times[$level]} -eq 0 ]] || [[ $elapsed -lt ${best_times[$level]} ]]; then
        best_times[$level]=$elapsed
        updated=true
    fi
    
    if [[ -f "$per_level_file" ]]; then
        while IFS=',' read -r name hs_level hs_time; do
            if [[ "$name" == "$player_name" && "$hs_level" == "$level" ]]; then
                continue
            fi
            echo "$name,$hs_level,$hs_time" >> "$temp_file"
        done < "$per_level_file"
    fi
    
    if $updated; then
        echo "$player_name,$level,${best_times[$level]}" >> "$temp_file"
    fi
    
    mv "$temp_file" "$per_level_file"
}

save_overall_score() {
    local total_time=$1
    local total_score=$2
    local temp_file=$(mktemp)
    local updated=false
    
    if [[ -f "$overall_file" ]]; then
        while IFS=',' read -r name score time; do
            if [[ "$name" == "$player_name" ]]; then
                if (( total_score > score )) || (( total_score == score && total_time < time )); then
                    echo "$player_name,$total_score,$total_time" >> "$temp_file"
                    updated=true
                else
                    echo "$name,$score,$time" >> "$temp_file"
                fi
            else
                echo "$name,$score,$time" >> "$temp_file"
            fi
        done < "$overall_file"
    fi
    
    if ! grep -q "$player_name" "$overall_file" && [[ $total_score -gt 0 ]]; then
        echo "$player_name,$total_score,$total_time" >> "$temp_file"
        updated=true
    fi
    
    if $updated; then
        sort -t',' -k2,2nr -k3,3n -o "$temp_file" "$temp_file"
        mv "$temp_file" "$overall_file"
    else
        rm "$temp_file"
    fi
}

show_highscores() {
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║               🏆 HIGH SCORES 🏆              ║"
    echo "╠══════════════════╦══════════╦═══════════════╣"
    echo "║ Player           ║ Score    ║ Avg Time      ║"
    echo "╠══════════════════╬══════════╬═══════════════╣"
    
    if [[ -f "$overall_file" ]]; then
        local count=0
        while IFS=',' read -r name score time && [[ $count -lt 5 ]]; do
            local avg_time=$((time / 3))
            printf "║ %-16s ║ %-8d ║ %02d:%02d         ║\n" \
                   "$name" "$score" $((avg_time/60)) $((avg_time%60))
            count=$((count+1))
        done < "$overall_file"
    else
        echo "║ No scores recorded yet!                   ║"
    fi
    
    echo "╚══════════════════╩══════════╩═══════════════╝"
}

show_image() {
    local image_file=$1
    if [[ -f "$image_file" ]]; then
        # Try various image viewers
        if command -v xdg-open &>/dev/null; then
            xdg-open "$image_file" >/dev/null 2>&1 &
        elif command -v feh &>/dev/null; then
            feh "$image_file" &
        else
            echo "Image display not available. See: $image_file"
            return
        fi
        local IMAGE_PID=$!
        sleep 15
        kill $IMAGE_PID 2>/dev/null
    else
        echo "Image not found: $image_file"
    fi
}

get_player_name() {
    clear
    echo "╔══════════════════════════════════════════════╗"
    echo "║       🏰 MAZE RUNNER - BASH EDITION 🏰      ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""
    read -p "Enter your name: " player_name
    [[ -z "$player_name" ]] && player_name="Player1"
    
    current_score=0
    level_times=()
    load_level_scores
    attempt=1
}

show_stats() {
    local player_line="PLAYER: $player_name"
    local level_line="LEVEL: $current_level   ATTEMPT: $attempt   SCORE: $current_score"
    
    echo "╔══════════════════════════════════════════════╗"
    printf "║ %-46s ║\n" "${player_line:0:46}"
    printf "║ %-46s ║\n" "${level_line:0:46}"
    echo "╟──────────────────────────────────────────────╢"
    
    for level in {1..3}; do
        if [[ ${best_times[$level]} -gt 0 ]]; then
            printf "║ LEVEL %d BEST: %02d:%02d %25s ║\n" \
                   $level $((best_times[$level]/60)) $((best_times[$level]%60)) ""
        else
            printf "║ LEVEL %d BEST: %-8s %25s ║\n" $level "--:--" ""
        fi
    done
    
    if [[ $current_start_time -gt 0 ]]; then
        local current_time=$(date +%s)
        local elapsed=$((current_time - current_start_time))
        printf "║ CURRENT TIME: %02d:%02d %28s ║\n" \
               $((elapsed/60)) $((elapsed%60)) ""
    else
        printf "║ %-46s ║\n" "CURRENT TIME: --:--"
    fi
    
    echo "╚══════════════════════════════════════════════╝"
}

find_start_position() {
    for i in "${!maze[@]}"; do
        line="${maze[$i]}"
        for (( j=0; j<${#line}; j++ )); do
            if [[ "${line:$j:1}" == "P" ]]; then
                player_row=$i
                player_col=$j
                start_row=$i
                start_col=$j
                return
            fi
        done
    done
    player_row=19
    player_col=0
    start_row=19
    start_col=0
}

set_current_maze() {
    # Reset collected rewards
    unset collected_rewards
    declare -gA collected_rewards
    
    case $current_level in
        1) maze=("${maze1[@]}") ;;
        2) maze=("${maze2[@]}") ;;
        3) maze=("${maze3[@]}") ;;
        *) maze=("${maze1[@]}") ;;
    esac
    find_start_position
}

move_player() {
    local new_row=$((player_row + $1))
    local new_col=$((player_col + $2))
    
    if [[ $current_start_time -eq 0 ]]; then
        current_start_time=$(date +%s)
    fi
    
    if [[ $new_row -ge 0 && $new_row -lt 20 && $new_col -ge 0 && $new_col -lt 20 ]]; then
        local target_char="${maze[$new_row]:$new_col:1}"
        
        if [[ $target_char == "E" ]]; then
            player_row=$new_row
            player_col=$new_col
            
            local end_time=$(date +%s)
            local elapsed=$((end_time - current_start_time))
            level_times[$current_level]=$elapsed
            
            save_level_score $current_level $elapsed
            
            display_maze
            echo ""
            echo "╔══════════════════════════════════════════════╗"
            printf "║          🎉 LEVEL %d COMPLETED! 🎉             ║\n" $current_level
            printf "║ Time: %02d:%02d                                 ║\n" $((elapsed/60)) $((elapsed%60))
            printf "║ Score: %-36d ║\n" $current_score
            echo "╚══════════════════════════════════════════════╝"
            
            if [[ $current_level -lt 3 ]]; then
                sleep 2
                ((current_level++))
                set_current_maze
                current_start_time=0
                return 1
            else
                local total_time=0
                for t in "${level_times[@]}"; do
                    total_time=$((total_time + t))
                done
                
                save_overall_score $total_time $current_score
                
                show_image "$WIN_IMAGE"
                echo ""
                echo "╔══════════════════════════════════════════════╗"
                echo "║          🏆 GAME COMPLETED! 🏆               ║"
                printf "║ Total Score: %-31d ║\n" $current_score
                printf "║ Total Time: %02d:%02d                                ║\n" \
                       $((total_time/60)) $((total_time%60))
                echo "╚══════════════════════════════════════════════╝"
                
                show_highscores
                
                read -p "Play again? (y/n): " choice
                case "$choice" in
                    y|Y) 
                        current_level=1
                        current_score=0
                        level_times=()
                        set_current_maze
                        current_start_time=0
                        ((attempt++))
                        return 1
                        ;;
                    *) 
                        echo "Thanks for playing!"
                        exit 0 
                        ;;
                esac
            fi
        fi
        
        if [[ $target_char != "#" ]]; then
            if [[ $target_char == "$" || $target_char == "♥" ]]; then
                if [[ -z "${collected_rewards["$new_row,$new_col"]}" ]]; then
                    collected_rewards["$new_row,$new_col"]=1
                    if [[ $target_char == "$" ]]; then
                        current_score=$((current_score + 1))
                    elif [[ $target_char == "♥" ]]; then
                        current_score=$((current_score + 5))
                    fi
                fi
            fi
            
            player_row=$new_row
            player_col=$new_col
        fi
    fi
    return 0
}

display_maze() {
    clear
    show_stats
    
    printf "╔"
    for ((j=0; j<20; j++)); do
        printf "═"
    done
    printf "╗\n"
    
    for ((i=0; i<20; i++)); do
        printf "║"
        for ((j=0; j<20; j++)); do
            char="${maze[$i]:$j:1}"
            if (( i == player_row && j == player_col )); then
                printf "P"
            else
                if (( i == start_row && j == start_col )); then
                    printf "."
                else
                    if [[ -n "${collected_rewards["$i,$j"]}" ]]; then
                        if [[ "$char" == "$" || "$char" == "♥" ]]; then
                            printf "."
                        else
                            if [[ "$char" == "#" ]]; then
                                printf "█"
                            else
                                printf "%s" "$char"
                            fi
                        fi
                    else
                        if [[ "$char" == "#" ]]; then
                            printf "█"
                        else
                            printf "%s" "$char"
                        fi
                    fi
                fi
            fi
        done
        printf "║\n"
    done
    
    printf "╚"
    for ((j=0; j<20; j++)); do
        printf "═"
    done
    printf "╝\n"
    
    echo "CONTROLS: w=↑ a=← s=↓ d=→ q=quit"
    echo "COLLECT: $=1pt, ♥=5pts"
    echo "EXIT: Find the 'E' position"
}

game_over() {
    clear
    echo "╔══════════════════════════════════════════════╗"
    echo "║               ██████  GAME OVER ██████       ║"
    echo "║                                              ║"
    echo "║          Better luck next time!              ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""
    
    show_image "$LOSE_IMAGE"
    
    echo ""
    read -p "Play again? (y/n): " choice
    case "$choice" in
        y|Y) 
            current_level=1
            current_score=0
            level_times=()
            set_current_maze
            current_start_time=0
            ((attempt++))
            ;;
        *) 
            echo "Thanks for playing!"
            exit 0 
            ;;
    esac
}

main_game_loop() {
    while true; do
        display_maze
        
        read -rsn1 key
        
        case $key in
            w) move_player -1 0 ;;
            a) move_player 0 -1 ;;
            s) move_player 1 0 ;;
            d) move_player 0 1 ;;
            q) game_over ;;
        esac

        case $? in
            1) 
                continue
                ;;
            *) 
                ;;
        esac
    done
}

while true; do
    get_player_name
    set_current_maze
    main_game_loop
done

