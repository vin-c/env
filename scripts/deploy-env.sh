#!/bin/bash

home=~
cd $home/env

git submodule init && git submodule update

for file in .gitconfig .gitignore-global .gitmodules .screenrc .tmux.conf .vimrc \
   .zshrc .zshrc.oh-my-zsh .oh-my-zsh ; do

   if [[ -h $home/$file ]]; then
      rm $home/$file -f
   elif [[ -e $home/$file ]]; then
      mv $home/$file $home/$file.bak
   fi

   ln -s $home/env/$file $home/$file
done

if [[ ! -e /bin/zsh ]]; then
   sudo apt-get install -y zsh vim atool screen tmux
fi

chsh -s /bin/zsh
/bin/zsh

if [[ -e /bin/zsh ]]; then
   source $home/.zshrc
fi

echo "virtualenvwrapper script as root..."
sudo cp scripts/virtualenvwrapper.sh /usr/local/bin/virtualenvwrapper.sh
