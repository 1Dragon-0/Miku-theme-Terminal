function fish_prompt --description 'Miku prompt: powerline arrow with short path'
    set -l last_status $status

    # Short path: "~" in home, "~/dir" one level down, "…/dir" deeper.
    set -l dir
    set -l parent
    if type -q path
        set dir (path basename -- $PWD)
        set parent (path dirname -- $PWD)
    else
        # fish < 3.5 has no `path` builtin.
        set dir (basename -- $PWD)
        set parent (dirname -- $PWD)
    end

    set -l cwd
    if test "$PWD" = /
        set cwd '/'
    else if test "$PWD" = "$HOME"
        set cwd '~'
    else if test "$parent" = "$HOME"
        set cwd "~/$dir"
    else
        set cwd "…/$dir"
    end

    set -l dark '#0B1220'
    set -l teal '#39C5BB'
    set -l pink '#E12885'

    # Error block, only when the last command failed.
    if test $last_status -ne 0
        set_color --background $pink $dark
        echo -n " ✘ $last_status "
        set_color --background normal $pink
        printf '\ue0b0'
    end

    # Path block.
    set_color --background $teal $dark
    echo -n " $cwd "
    set_color --background normal $teal
    printf '\ue0b0'

    # Git block: branch + dirty state, only when git is installed.
    set -l git_info
    if command -q git
        set -l branch (command git symbolic-ref --quiet --short HEAD 2>/dev/null)
        if test -n "$branch"
            set git_info $branch
            if not command git diff --quiet --ignore-submodules HEAD 2>/dev/null
                set git_info "$git_info*"
            end
            if test -n (command git ls-files --others --exclude-standard --directory 2>/dev/null | head -n1)
                set git_info "$git_info?"
            end
        else
            set -l sha (command git rev-parse --short HEAD 2>/dev/null)
            test -n "$sha"; and set git_info $sha
        end
    end

    if test -n "$git_info"
        set_color --background $pink $dark
        echo -n " $git_info "
        set_color --background normal $pink
        printf '\ue0b0'
    end

    # Final indicator.
    set_color normal
    if test $last_status -eq 0
        set_color --bold $teal
    else
        set_color --bold $pink
    end
    echo -n ' ❯ '
    set_color normal
end
