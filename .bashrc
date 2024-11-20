# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc

[ -x "/usr/bin/most" ] && export PAGER=most

export ANSIBLE_BECOME_PASSWORD_FILE='extra/.sudo_passwd'
export ANSIBLE_REMOTE_USER='vincent.gatignol-jamon'

export HISTCONTROL="ignoreboth:erasedups";
export PROMPT_COMMAND="history -a";
export HISTIGNORE="export AWS_:l :env :git rebase --interactive :g diff :gcp "

# aliases
alias c=clear
alias code=codium
alias g=git
alias ga='git add'
alias gb='git branch'
alias gc='git commit -v'
alias gco='git checkout'
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias gf='git fetch'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias gp='git push'
alias gpr='git pull --rebase'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase -i'
alias grbm='git rebase $(git_main_branch)'
alias grbs='git rebase --skip'
alias gst='git status'
alias gsu='git submodule update'
alias l='ls -lah'
alias psx='ps aux | less'
alias vgssh='evssh -l ${ANSIBLE_REMOTE_USER}'
alias setremote="export ANSIBLE_BECOME_PASSWORD_FILE='extra/.sudo_passwd' ANSIBLE_REMOTE_USER='vincent.gatignol-jamon'"
alias unsetremote="unset ANSIBLE_BECOME_PASSWORD_FILE ANSIBLE_REMOTE_USER"

# work env
alias m=molecule
alias mconverge='molecule converge'
alias mcreate='molecule create'
alias mdestroy='molecule destroy'
alias mtest='molecule test'
alias mverify='molecule verify'
alias tf=terraform
