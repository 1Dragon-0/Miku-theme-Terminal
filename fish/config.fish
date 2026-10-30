if status is-interactive
    # No greeting: fastfetch takes that space.
    set -g fish_greeting

    # fastfetch when opening a terminal, but not in nested shells.
    if command -q fastfetch; and not set -q FASTFETCH_SHOWN
        set -gx FASTFETCH_SHOWN 1
        fastfetch
        echo
    end
end
