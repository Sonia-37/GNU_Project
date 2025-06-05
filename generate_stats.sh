#!/bin/bash

# Generuj dane
echo "Player,Score,Time" > scores.csv
awk -F',' '{print $1","$2","$3}' maze_overall_scores.txt >> scores.csv

# Generuj wykres
gnuplot << EOF
set datafile separator ','
set terminal png size 801,600
set output 'maze_stats.png'
set title 'Maze Runner Statistics'
set xlabel 'Player'
set ylabel 'Score'
set style data histograms
set style fill solid

set boxwidth 0.8
set grid ytics
set key off
set xtics rotate by -45

plot 'scores.csv' using 2:xtic(1) titleplot 'scores.csv' using 2:xtic(1) title 'Scores' linecolor rgb "#3498db" 'Scores' linecolor rgb "#3498db"
EOF

echo "Wygenerowano wykres: maze_stats.png"


