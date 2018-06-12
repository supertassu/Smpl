#!/usr/bin/env zsh

setopt prompt_subst

# turns seconds into human readable time
# 165392 => 1d 21h 56m 32s
# https://github.com/sindresorhus/pretty-time-zsh
prompt_smpl_human_time_to_var() {
    local human total_seconds=$1
    local days=$(( total_seconds / 60 / 60 / 24 ))
    local hours=$(( total_seconds / 60 / 60 % 24 ))
    local minutes=$(( total_seconds / 60 % 60 ))
    local seconds=$(( total_seconds % 60 ))

    (( days > 0 )) && human+="${days}d "
    (( hours > 0 )) && human+="${hours}h "
    (( minutes > 0 )) && human+="${minutes}m "
    human+="${seconds}s"

    echo "$human"
}

prompt_smpl_command_exists() {
    command -v $1 > /dev/null 2>&1
    echo "$?"
}

# git related stuff

prompt_smpl_git_branch() {
    local git_current_branch="$(git branch 2>/dev/null | grep '^*' | colrm 1 2 )"
    [[ -z "$git_current_branch" ]] && return
    echo " on %B%F{blue}\ue725 ${git_current_branch}%f%b"
}

# shamelessy stolen from https://github.com/sindresorhus/pure/blob/master/pure.zsh

prompt_smpl_check_git_arrows() {
    setopt localoptions noshwordsplit

    [[ -z "$1" ]] && return

	local splitted="$(echo $1 | awk '{
        if ($1 != "0")
            printf "⇡"
        if ($2 != 0)
            printf "⇣"
        }')"
    echo "$splitted"

    echo $splitted | awk '{ gsub(/[ \t]+$/, "", $1); length("$1") == 0 ? "" : " " $1 }'
}

prompt_smpl_set_title() {
    setopt localoptions noshwordsplit

    # emacs terminal does not support settings the title
    (( ${+EMACS} )) && return

    case $TTY in
        # Don't set title over serial console.
        /dev/ttyS[0-9]*) return;;
    esac

    local -a opts
    case $1 in
        expand-prompt) opts=(-P);;
        ignore-escape) opts=(-r);;
    esac

    # Set title atomically in one print statement so that it works
    # when XTRACE is enabled.
    print -n $opts $'\e]0;'${hostname}${2}$'\a'
}

prompt_smpl_render() {
    NEWLINE=$'\n'
    PROMPT_TEXT="${NEWLINE}%B$fg[grey]‣$reset_color%b"

    if [[ ! -v PROMPT_SMPL_HIDE_USER_SSH ]] then;
        [[ -v SSH_CLIENT ]] && PROMPT_TEXT+=" %B%F{cyan}%n@%m%f%b"
    fi

    if [[ ! -v SSH_CLIENT ]] then;
        if [[ ! -v PROMPT_SMPL_HIDE_USER_ROOT ]] then;
            [[ $UID -eq 0 ]] && PROMPT_TEXT+=" %B%F{cyan}%n%f%b"
        fi
    fi

    if [[ ! -v PROMPT_SMPL_HIDE_TIME ]] then;
        PROMPT_TEXT+=" at %B%T%b"
    fi

    if [[ ! -v PROMPT_SMPL_HIDE_CWD ]] then; 
        PROMPT_TEXT+=" in %B%F{yellow}%~%f%b"
    fi

    local SPACE_ADDED=false

    if [[ ! -v PROMPT_SMTL_HIDE_GIT_BRANCH ]] then;
        PROMPT_TEXT+="`prompt_smpl_git_branch`"
        if [[ ! -v PROMPT_SMTL_DISABLE_DIRTY_CHECK ]] then;
            command git diff --no-ext-diff --quiet --exit-code >> /dev/null &> /dev/null
            if [[ "$?" -eq 1 ]] then; 
                PROMPT_TEXT+=" %F{cyan}☆%f"
                SPACE_ADDED=true
            else
                command git diff HEAD --no-ext-diff --quiet --exit-code >> /dev/null &> /dev/null
                [[ "$?" -eq 1 ]] && PROMPT_TEXT+=" %F{cyan}★%f"
                SPACE_ADDED=true
            fi 
        fi

        if [[ ! -v PROMPT_SMPL_DISABLE_GIT_PULL_PUSH_CHECK ]] then;
            local output="$(git rev-list --left-right --count HEAD...@'{u}' 2> /dev/null)"
            local ARROWS="$(prompt_smpl_check_git_arrows $output)"
            [[ "$SPACE_ADDED" -eq "false" ]] && PROMPT_TEXT+=" "
            PROMPT_TEXT+="%F{cyan}$ARROWS%f"
        fi
    fi

    # https://github.com/denysdovhan/spaceship-prompt/blob/master/sections/node.zsh
    if [[ ! -v PROMPT_SMPL_HIDE_NVM ]] then;
        if [[ -f package.json || -d node_modules || -f *.js || -f *.jsx ]] then;
            if [[ "`prompt_smpl_command_exists nvm`" -eq 0 ]] then;
                node_version=$(nvm current 2>/dev/null)
            elif [[ "`prompt_smpl_command_exists nodenv`" -eq 0 ]]; then
                node_version=$(nodenv version-name)
            else
                node_version="system"
            fi

            if [[ $node_version == "system" || $node_version == "node" ]] then;
            elif [[ -v node_version ]]; then
                PROMPT_TEXT+=" using %B%F{green}⬢ ${node_version}%f%b"
            fi
        fi
    fi

    if [[ ! -v PROMPT_SMPL_HIDE_EXEX_TIME && -v prompt_smpl_exec_start ]] then; 
        now=$(($(date +%s%N)/1000000))
        elapsed=$(($now-$prompt_smpl_exec_start))

        if [[ -v PROMPT_SMPL_SHOW_LOW_TIMES || elapsed -gt $PROMPT_SMPL_EXEC_TIME_TRESHOLD ]] then;
            if [[ ! -v PROMPT_SMPL_USE_MILLIS_ON_EXEC_TIME ]] then;
                elapsedSec=$(($elapsed/1000))
                elapsed="`prompt_smpl_human_time_to_var $elapsedSec`"
            else
                elapsed+="ms"
            fi
            PROMPT_TEXT+=", took %B%F{magenta}${elapsed}%f%b"
        fi

        unset prompt_smpl_exec_start
    fi

    # borrowed from https://github.com/sindresorhus/pure/blob/master/pure.zsh#L147-L152
    local -ah ps1
    ps1=(
        $PROMPT_TEXT
        $NEWLINE
        "⤐  "
    )

    PROMPT="${(j..)ps1}"
}

prompt_smpl_preexec() {
    prompt_smpl_set_title 'ignore-escape' "$PWD:t: $2"
    prompt_smpl_exec_start=$(($(date +%s%N)/1000000))
}

prompt_smpl_precmd() {
    prompt_smpl_set_title 'expand-prompt' '%~'
}

prompt_smpl_setup() {
    autoload -U colors && colors

    setopt prompt_subst

    add-zsh-hook precmd prompt_smpl_render
    add-zsh-hook precmd prompt_smpl_precmd
    add-zsh-hook preexec prompt_smpl_preexec

    if [[ ! -v PROMPT_SMPL_EXEC_TIME_TRESHOLD ]] then;
        export PROMPT_SMPL_EXEC_TIME_TRESHOLD=1000
    fi

    PROMPT=""
}

prompt_smpl_setup
