setopt extended_glob
setopt prompt_subst

# prioritize dircolors
local dircolors_theme_path=${ZSH_THEME_HANPEN_DIRCOLORS_THEME_PATH:-$HOME/.dircolors}
if (( ${+commands[dircolors]} )) && [ -f $dircolors_theme_path ]; then
  eval "$(dircolors $dircolors_theme_path)"
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
fi

# colorize less
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;38;5;208m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[04;38;5;111m'
if (( ${+commands[src-hilite-lesspipe.sh]} )); then
  export LESSOPEN="| ${commands[src-hilite-lesspipe.sh]} %s"
fi

# (async) git info
local git_info
local prompt_git_info

ZSH_THEME_GIT_PROMPT_PREFIX="%K{235} %{$fg_bold[magenta]%} %{$fg_no_bold[magenta]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX=''
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%} ✔"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[red]%} ✘"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg_bold[cyan]%} ✭"
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg_bold[green]%} ✚"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg_bold[yellow]%} ✱"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg_bold[blue]%} ➜"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg_bold[red]%} ✖"
ZSH_THEME_GIT_PROMPT_STASHED="%{$fg_no_bold[white]%} ☰"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg_bold[magenta]%} ═"
ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_DETAILED=1
ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE=" %{$fg_bold[cyan]%}⬆ %{$fg_no_bold[cyan]%}"
ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE=" %{$fg_bold[red]%}⬇ %{$fg_no_bold[red]%}"

if (( ${+functions[async_init]} )); then
  prompt_git_info='$git_info %k'

  _hanpen_zsh_theme_git_info_complete() {
    git_info=$3
    zle reset-prompt
  }

  _hanpen_zsh_theme_git_info_print() {
    setopt extended_glob
    cd $1
    echo "$(git_prompt_info)$(git_prompt_status)${$(git_remote_status)/[^ ]##}"
  }

  _hanpen_zsh_theme_git_info_start() {
    git_info=''
    async_job git_info_worker _hanpen_zsh_theme_git_info_print $PWD
  }

  async_start_worker git_info_worker -u -n
  async_register_callback git_info_worker _hanpen_zsh_theme_git_info_complete
  precmd_functions+=(_hanpen_zsh_theme_git_info_start)
else
  prompt_git_info='$(git_prompt_info)$(git_prompt_status)${$(git_remote_status)/[^ ]##} %k'
fi

# command execution time
local cmd_exec_time
local prompt_cmd_exec_time='%{$reset_color%}${cmd_exec_time}'

if zmodload -F -a zsh/datetime +p:EPOCHSECONDS; then
  integer cmd_exec_time_start

  _hanpen_zsh_theme_cmd_exec_time_set() {
    cmd_exec_time_start=$EPOCHSECONDS
  }

  _hanpen_zsh_theme_cmd_exec_time_show() {
    integer elapsed=${EPOCHSECONDS}-${cmd_exec_time_start:-$EPOCHSECONDS}
    if (( elapsed > ${ZSH_THEME_HANPEN_CMD_MAX_EXEC_TIME:=5} )); then
      cmd_exec_time='↪ '
      if (( ${+commands[pretty-time]} )) || (( ${+functions[pretty-time]} )); then
        cmd_exec_time+=$(pretty-time $elapsed)
      else
        cmd_exec_time+="${elapsed}s"
      fi
    else
      cmd_exec_time=''
    fi
  }

  preexec_functions+=(_hanpen_zsh_theme_cmd_exec_time_set)
  precmd_functions+=(_hanpen_zsh_theme_cmd_exec_time_show)
fi

# prompt
local prompt_status='%(?..%K{red} %{$fg[black]%}✘ %? )%k'
local prompt_time='%K{247} %{$fg[black]%}%D{%T} %k'
local prompt_user='%K{237} %{$fg[yellow]%}%n %k'
local prompt_dir='%K{236} %F{033}%~ %k'
local prompt_char='%(?.%{$fg_bold[green]%}.%{$fg_bold[red]%})» %f%b'

PROMPT="
${prompt_status}${prompt_time}${prompt_user}${prompt_dir}${prompt_git_info}${prompt_cmd_exec_time}
${prompt_char}"
