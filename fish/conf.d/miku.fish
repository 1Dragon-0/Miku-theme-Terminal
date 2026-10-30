# Miku night palette for fish.
# Background #0B1220 · teal #39C5BB · pink #E12885

# --- Syntax ---
set -g fish_color_normal       '#C9D6E3'
set -g fish_color_command      '#39C5BB'
set -g fish_color_keyword      '#E12885'
set -g fish_color_param        '#C9D6E3'
set -g fish_color_quote        '#F0C674'
set -g fish_color_redirection  '#5AA9E6' --bold
set -g fish_color_end          '#39C5BB'
set -g fish_color_error        '#F26D8D'
set -g fish_color_comment      '#4A5A6E' --italics
set -g fish_color_operator     '#6FE0D6'
set -g fish_color_escape       '#6FE0D6'
set -g fish_color_autosuggestion '#4A5A6E'
set -g fish_color_valid_path   --underline
set -g fish_color_selection    '#EAF3F8' --bold --background='#1E5A5C'
set -g fish_color_search_match --background='#1E5A5C'
set -g fish_color_history_current --bold

# --- Status and context ---
set -g fish_color_cwd          '#39C5BB'
set -g fish_color_cwd_root     '#E12885'
set -g fish_color_user         '#6FE0D6'
set -g fish_color_host         '#5AA9E6'
set -g fish_color_host_remote  '#F0C674'
set -g fish_color_status       '#F26D8D'
set -g fish_color_cancel       --reverse

# --- Pager / completion ---
set -g fish_pager_color_completion          '#C9D6E3'
set -g fish_pager_color_description         '#7A8CA0'
set -g fish_pager_color_prefix              '#39C5BB' --bold
set -g fish_pager_color_progress            '#4A5A6E' --background='#0B1220'
set -g fish_pager_color_selected_background --background='#1E5A5C'
set -g fish_pager_color_selected_completion '#EAF3F8'
set -g fish_pager_color_selected_description '#9CE8B0'
