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

prompt_smtp_git_branch() {
    local git_current_branch="$(git branch 2>/dev/null | grep '^*' | colrm 1 2)"
    [[ -z "$git_current_branch" ]] && return
    echo " on %B%F{yellow}${git_current_branch}%f%b"
}

prompt_smpl_render() {
    NEWLINE=$'\n'
    PROMPT_TEXT="${NEWLINE}%B$fg[grey]‣$reset_color%b"

    if [[ ! -v PROMPT_SMPL_HIDE_TIME ]] then;
        PROMPT_TEXT+=" at %B%T%b"
    fi

    if [[ ! -v PROMPT_SMPL_HIDE_CWD ]] then; 
        PROMPT_TEXT+=" in %B%F{blue}%~%f%b"
    fi

    if [[ ! -v PROMPT_SMTL_HIDE_GIT_BRANCH ]] then;
        PROMPT_TEXT+="`prompt_smtp_git_branch`"
        if [[ ! -v PROMPT_SMTL_DISABLE_DIRTY_CHECK ]] then;
            command git diff --no-ext-diff --quiet --exit-code >> /dev/null &> /dev/null
            if [[ "$?" -eq 1 ]] then; 
                PROMPT_TEXT+="?"
            else
                command git diff HEAD --no-ext-diff --quiet --exit-code >> /dev/null &> /dev/null
                [[ "$?" -eq 1 ]] && PROMPT_TEXT+="!"
            fi 
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
    prompt_smpl_exec_start=$(($(date +%s%N)/1000000))
}

prompt_smpl_setup() {
    autoload -U colors && colors

    setopt prompt_subst

    precmd_functions=(prompt_smpl_render)
    preexec_functions=(prompt_smpl_preexec)

    if [[ ! -v PROMPT_SMPL_EXEC_TIME_TRESHOLD ]] then;
        export PROMPT_SMPL_EXEC_TIME_TRESHOLD=1000
    fi

    PROMPT=""
}

prompt_smpl_setup
