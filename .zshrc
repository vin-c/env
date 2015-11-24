# Created by vinc

READNULLCMD=${PAGER:-/usr/bin/pager}

# Load Grid environment
if [[ -f /etc/profile.d/grid-env.sh ]]; then
	source /etc/profile.d/grid-env.sh
	export PATH=/opt/glite/yaim/bin:$PATH
	alias gjc='glite-wms-job-submit -a'
	alias gjs='glite-wms-job-status'
fi

# Load openstask testing creds
if [[ -f ~/scripts/creds ]]; then
        source ~/scripts/creds
fi

# SCM @ IN2P3
export SVN_SSH=ssh

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
alias ll='ls $LS_OPTIONS -laFh'
alias setcl='export CLASSPATH=.:$CLASSPATH'
alias setdp='export DISPLAY=":0"'

# debian
alias acs='apt-cache search'
alias acss='apt-cache show'
alias ags='apt-get source'
alias agU='sudo apt-get update'
alias agu='sudo apt-get upgrade'
alias agdu='sudo apt-get dist-upgrade'
alias agi='sudo apt-get install'
alias agrm='sudo apt-get remove'
alias agrmp='sudo apt-get remove --purge'
alias ag='sudo apt-get'
alias acs='aptitude search'
alias acp='apt-cache policy'

# redhat
alias yu='sudo yum update'
alias yi='sudo yum install'
alias ys='yum search'
alias yv='yum info'

# Global ZSH
[ -x "/usr/bin/most" ] && export PAGER=most
SAVEHIST=40000
HISTSIZE=40000
HISTFILE=$HOME/.history
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
			     /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

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
prompt(){
	autoload colors
	colors
	color_isok="%(?.%F{green}.%F{red})"
	export PS1="%T $color_isok%n:%l %S%m%s%f:%3~%{$reset%}% %F{cyan}\${vcs_info_msg_0_}%f# "

}
prompt
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
bindkey '^[Oa'    history-beginning-search-backward
bindkey '^[[1;5A' history-beginning-search-backward
bindkey '^[[A'    history-beginning-search-backward
bindkey '^[OA'    history-beginning-search-backward

bindkey '^[Ob'    history-beginning-search-forward
bindkey '^[[1;5B' history-beginning-search-forward
bindkey '^[[B'    history-beginning-search-forward
bindkey '^[OB'    history-beginning-search-forward

bindkey "^A" beginning-of-line
bindkey "^E" end-of-line

# Set terminal title to hostname
case $TERM in
    xterm*)
        precmd () {print -Pn "\e]0;%m\a"}
        ;;
esac
