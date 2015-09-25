# Created by vinc

# Load Grid environment
if [[ -f /etc/profile.d/grid-env.sh ]]; then
	source /etc/profile.d/grid-env.sh
	export PATH=/opt/glite/yaim/bin:$PATH
	alias yu='sudo yum update'
	alias yi='sudo yum install'
	alias ys='yum search'
	alias yv='yum info'
	alias gjc='glite-wms-job-submit -a'
	alias gjs='glite-wms-job-status'
else
	alias acs='aptitude search'
	alias acp='apt-cache policy'
fi

alias bat='upower -i /org/freedesktop/UPower/devices/battery_BAT0'
alias dfh='df -h'
# SCM @ IN2P3
export SVN_SSH=ssh
