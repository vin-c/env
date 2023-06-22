#!/bin/bash

home=~
cd ${home}/env

sudo apt install -y git virtualenv virtualenvwrapper zsh vim atool screen tmux terminator keepassxc seafile-gui firefox-esr powerline

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

mkdir ${home}/.config/terminator
sudo cp conf/terminator.config ${home}/.config/terminator/config

mkdir ${home}/.docker
sudo cp conf/docker_config.json ${home}/.docker/config.json

chsh -s /bin/zsh
/bin/zsh

if [[ -e /bin/zsh ]]; then
   source ${home}/.zshrc
fi

mkdir -p ${home}/.config/systemd/user/
cp ${home}/env/conf/ssh-agent.service ${home}/.config/systemd/user/ssh-agent.service
systemctl --user daemon-reload
systemctl --user enable ssh-agent.service
