# dotfiles

The purpose of this repository is to version control various dotfiles from my home directory.
I am following the example provided in `/dotdocs/A simpler way to manage your dotfiles _ Anand Iyer.pdf`.

## .zshrc
My terminal setup. Contains very helpful bash/zsh alises and functions.

### Alias Highlights
I tried to group my aliases by basic function. Here are a few of the ones that I use all the time

awslogin
: I only have to enter my password one time and it logs me into each environment that I use frequently all at the same time.
It uses a function _awslogin() to do the login itself.

clip
: Used at the end of a pipe chain `cmd1 | cmd2 | clip` to copy the result to my clipboard for easy pasting

prettyjson
: Formats json output for easier reading

keycloak
: Runs a local keycloak instance with a little config thrown


### Functions
Various functions I've written as helpers for things I do all the time

awsreset
: Clears out my ~/.aws folder of any cached login data. Can be used in any directory, will always put you back where you were.

killport
: kills an active port.
: `killport 8080`

gethost
: Gets the host of a kubernetes ingress configuration by name and copies it to the clipboard
: `gethost my-ingress`

kgp
: runs `kubectl get pods`. Can optionally pass a string to match specific pods
: `kgp` returns standard `get pods` output
: `kgp matchstring` returns a list of pods that have names that match

klp
: gets logs for pods that match the input. Handles multiple matches by interactively providing details about multple matches.
Can optionally pass the -f flag for streaming logs
: `klp matchstring`
: `klp matchstring -f`

decode_k8s_secret
: Decodes a secret that matches the input. Interactively lets you choose what property you want to decode.
: `decode_k8s_secret matchstring`

restartdeployment
: Restarts a deployment that matches the input. Can optionally pass how many replicas you want, defaults to 1
: `restartdeployment matchstring`
: `restartdeployment my-deployment 2` scales deployment called "my-deployment" to 0 and then 2

## .gitconfig
Git specific aliases that can be used from the git library. For instance `git cob` runs `git checkout -b`.
Basically ripped off from [Haacked](https://haacked.com/).
Lots of cool stuff in there. Full disclosure, I don't always use all of these, but I get a _ton_ of use out of
- bdone
- cob
- co
- wip
- ec
### Sources
[Original Aliases Article](https://haacked.com/archive/2014/07/28/github-flow-aliases/)

[Full List of Aliases from Haacked](https://github.com/haacked/dotfiles/blob/main/git/gitconfig.aliases.symlink)

## .p10k.zsh
My .p10k zsh theme configuration

## .aws/config
My aws config
