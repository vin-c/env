# Created by vinc

# Oh-my-zsh
source ~/.zshrc.oh-my-zsh
READNULLCMD=${PAGER:-/usr/bin/pager}

# Add Puppet in PATH
export PATH=$PATH:/opt/puppetlabs/bin

# Aliases
alias h=' search_history'
alias bat='upower -i /org/freedesktop/UPower/devices/battery_BAT0'
alias dfh='df -h'
alias cp='cp -i'
alias mv='mv -i'
alias rm=' rm -i'
alias c=clear
alias psx='ps aux | $PAGER'
alias ls='ls $LS_OPTIONS -F'
alias lart='ls -lart'
#alias ll='ls $LS_OPTIONS -laFh'
alias setcl='export CLASSPATH=.:$CLASSPATH'
alias setdp='export DISPLAY=":0"'
alias rgrep='grep -R'
alias vi='vim'
alias nocom="sed -r '/^(\s*#|$)/d;'"
alias os="openstack"
alias a2dp="/opt/pylover_a2dp/a2dp.py 00:18:09:93:A5:1A"
alias a2dp_black="/opt/pylover_a2dp/a2dp.py FC:A8:9A:F0:CC:F2"
alias myjohn="/home/vinc/Public/ldap-check-pwd/john/run/john"
alias glogb='git log --oneline --graph --decorate --branches --abbrev-commit'
alias gpr='git pull --rebase'
alias grpo='git remote prune origin'
#alias gloga='git log --all --oneline --graph --decorate --format="%h %<(90,trunc)%s"'
# debian
#alias acs='apt-cache search'
alias acs='aptitude search'
alias acss='apt-cache show'
alias ags='apt-get source'
alias agU='sudo apt update'
alias agu='sudo apt upgrade'
alias agdu='sudo apt dist-upgrade'
alias agi='sudo apt install'
alias agrm='sudo apt remove'
alias agrmp='sudo apt remove --purge'
alias ag='sudo apt'
alias acp='apt policy'
alias agarc='sudo apt autoremove && sudo apt clean'
alias agar='sudo apt autoremove'
alias agc='sudo apt clean'
alias szs='sudo -H -s zsh -c '\''screen -x || cd && screen'\'

# redhat/centos
alias yu='sudo yum update'
alias yi='sudo yum install'
alias ys='yum search'
alias yv='yum info'
alias sr='sudo systemctl restart'
alias ss='sudo systemctl status'
alias sdr='sudo systemctl daemon-reload'

# docker
if [[ -e /usr/bin/docker ]]; then
   alias dok='docker'
   alias dops='docker ps -a'
   alias dorm='docker rm'
   alias doip='docker image prune'
   alias db='docker build -t local_build:latest .'
   alias dr='docker run --rm -t -d --name plop local_build:latest && docker exec -it plop /bin/bash ; docker stop plop'
   alias drp='docker run --rm --privileged -t -d --name plop local_build:latest && docker exec -it plop /bin/bash ; docker stop plop'
fi

# Dell OpenManage
alias racadm='sudo /opt/dell/srvadmin/sbin/racadm'

# Braincube
alias gopp='cd ~/Public/infra/environments/env_preprod'
alias goblue='cd ~/Public/infra/environments/env_blue'
alias gocloud='cd ~/Public/infra/environments/env_cloud'
alias goansible='cd ~/Public/infra/ansible'

# Global ZSH
[ -x "/usr/bin/most" ] && export PAGER=most
SAVEHIST=40000
HISTSIZE=40000
HISTFILE=$HOME/.history

# Use modern completion system
autoload -Uz compinit
compinit -u

zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
			     /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2 eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

autoload run-help

setopt autocd
setopt correct
setopt autopushd
setopt PUSHD_IGNORE_DUPS
setopt MENU_COMPLETE
setopt nolistbeep
setopt listtypes
setopt listpacked
setopt nohup
setopt promptsubst
setopt HIST_IGNORE_DUPS
setopt histignorealldups
setopt HIST_IGNORE_SPACE
setopt share_history

MAIL=/var/spool/mail/$USERNAME

export HISTORY SAVEHIST HISTFILE HISTSIZE MAIL
export EDITOR=vi

# functions
ax () {
	if [ $# -eq 0 ]; then echo 'Gimme a file to unpack !'; return; fi
	if [ ! -x /usr/bin/atool ]; then echo 'Need "agi atool"'; return; fi
	if [ ! -x /bin/mktemp ]; then echo 'Need "mktemp"'; return; fi
	TMP=`mktemp /tmp/aunpack.XXXXXXXXXX`
	atool -x --save-outdir=$TMP "$@"
	DIR="`cat $TMP`"
	[ "$DIR" != "" -a -d "$DIR" ] && cd "$DIR"
	rm -rf $TMP
}

# prompt
if [ $UID -eq 0 ]; then NCOLOR="red"; else NCOLOR="white"; fi
RCOLOR="%(?.$fg[black]$bg[green].$fg[grey]$bg[red])"
PROMPT='%{$fg[$NCOLOR]%}%B%n%b%{$reset_color%}:%{$fg[blue]%}%B%c/%b%{$reset_color%} $(git_prompt_info)%{$RCOLOR%}%(!.#.$)%{$reset_color%} '

search_history() { fc -l -20000 | grep --color=always "$@" }
mf() { tbl $* | nroff -mandoc | $PAGER -s }
# options de 'less'
LESS="-eMr"
LESSCHARSET=latin1
export LESS LESSCHARSET

# ls
eval `dircolors -b`
LS_OPTIONS="--color"
export LS_OPTIONS
export LS_COLORS="no=00:fi=00:di=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;3:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:"

# Init Autojump, if installed
[ -r "/usr/share/autojump/autojump.zsh" ] && source /usr/share/autojump/autojump.zsh

# Bind keys for history
bindkey '^[Oa'      history-beginning-search-backward
bindkey '^[[1;5A'   history-beginning-search-backward
bindkey '^[[A'      history-beginning-search-backward
bindkey '^[OA'      history-beginning-search-backward

bindkey '^[Ob'      history-beginning-search-forward
bindkey '^[[1;5B'   history-beginning-search-forward
bindkey '^[[B'      history-beginning-search-forward
bindkey '^[OB'      history-beginning-search-forward

bindkey '^A'        beginning-of-line
bindkey '^E'        end-of-line

bindkey '^[[3~'     delete-char
bindkey '^[3;5~'    delete-char

# Set terminal title to hostname
case $TERM in
    xterm*|screen*)
        precmd () {print -Pn "\e]0;%m\a"}
        ;;
esac

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

# To include keyring with zsh ?
if [ -n "$DESKTOP_SESSION" ];then
    eval $(gnome-keyring-daemon --start)
    export SSH_AUTH_SOCK
fi

# python virtualenvs (for ansible)
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
export WORKON_HOME=~/Public/venvs/
source /usr/local/bin/virtualenvwrapper.sh
workon ansible2.9.7
