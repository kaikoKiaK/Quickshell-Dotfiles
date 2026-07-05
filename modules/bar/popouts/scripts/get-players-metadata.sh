#!/bin/sh
playerctl --all-players metadata --format '{{playerName}}~|~{{status}}~|~{{title}}~|~{{artist}}~|~{{position}}~|~{{mpris:length}}' 2>/dev/null
