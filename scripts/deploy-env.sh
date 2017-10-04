#!/bin/bash

home=~
cd $home/env

git submodule init && git submodule update

for file in .gitconfig .gitignore-global .gitmodules .screenrc .vimrc \
   .zshrc .zshrc.oh-my-zsh .oh-my-zsh ; do


   if [[ -h $home/$file ]]; then
      rm $home/$file -f
   elif [[ -e $home/$file ]]; then
      mv $home/$file $home/$file.bak
   fi
   ln -s $home/env/$file $home/$file
done

if [[ ! -e /bin/zsh ]]; then
   apt-get install -y zsh vim atool screen
fi

chsh -s /bin/zsh
/bin/zsh

if [[ -e /bin/zsh ]]; then
   source $home/.zshrc
fi

