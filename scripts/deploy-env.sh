#!/bin/bash

home=~
cd ${home}/env

sudo apt install -y git virtualenv virtualenvwrapper

git submodule init && git submodule update

for file in .gitconfig .gitignore-global .gitmodules .screenrc .tmux.conf .vimrc \
   .zshrc .zshrc.oh-my-zsh .oh-my-zsh ; do

   if [[ -h ${home}/${file} ]]; then
      rm ${home}/${file} -f
   elif [[ -e ${home}/${file} ]]; then
      mv ${home}/${file} ${home}/${file}.bak
   fi

   ln -s ${home}/env/${file} ${home}/${file}
done

if [[ ! -e /bin/zsh ]]; then
   sudo apt install -y zsh vim atool screen tmux terminator keepassxc seafile-client
fi

chsh -s /bin/zsh
/bin/zsh

if [[ -e /bin/zsh ]]; then
   source ${home}/.zshrc
fi

mkdir -p ${home}/.config/systemd/user/
cp ${home}/env/conf/ssh-agent.service ${home}/.config/systemd/user/ssh-agent.service
systemctl --user daemon-reload
systemctl --user enable ssh-agent.service
