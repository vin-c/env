#!/bin/bash

home=~
cd ${home}/env

sudo dnf install -y git virtualenv zsh vim atool tmux terminator powerline

git submodule init && git submodule update

for file in .gitconfig .gitignore-global .gitmodules .screenrc .tmux.conf .vimrc \
   .zshrc .zshrc.oh-my-zsh .oh-my-zsh .inputrc .bashrc ; do

   if [[ -h ${home}/${file} ]]; then
      rm ${home}/${file} -f
   elif [[ -e ${home}/${file} ]]; then
      mv ${home}/${file} ${home}/${file}.bak
   fi

   ln -s ${home}/env/${file} ${home}/${file}
done

mkdir ~/.config/terminator
ln -s conf/terminator.config ~/.config/terminator/config

chsh -s /bin/zsh
/bin/zsh

if [[ -e /bin/zsh ]]; then
   source ${home}/.zshrc
fi
