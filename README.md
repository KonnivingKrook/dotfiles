# dotfiles

The purpose of this repository is to version control various dotfiles from my home directory.
I am following the example provided in `/dotdocs/A simpler way to manage your dotfiles _ Anand Iyer.pdf`.

# Setup New Machine
```shell
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
git clone --bare git@github.com:HappyCerberus/dotfiles-demo.git $HOME/.dotfiles
dotfiles config --local status.showUntrackedFiles no
dotfiles checkout
```

If files will be overwritten, back them up first

```shell
mv ~/.gitconfig ~/.gitconfig_backup
dotfiles checkout
```
