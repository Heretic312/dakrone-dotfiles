# autoloads
autoload -U compinit
autoload -U promptinit
autoload colors
colors
compinit
promptinit

# path
export PATH=~/bin:/usr/local/bin:$PATH:/usr/local/sbin:/usr/local/sbin:/usr/libexec:/opt/local/bin:/opt/local/sbin:/usr/local/mysql/bin
# Path for Matasano's blackbag
export PATH=/usr/local/bin/blackbag:$PATH
# Path for git
export PATH=$PATH:/usr/local/git/bin
# Path for ruby gems
export PATH=$PATH:/var/lib/gems/1.8/bin
# Path for jruby
export PATH=$PATH:~/src/ruby/jruby/bin
# Path for postgres
export PATH=$PATH:/opt/local/lib/postgresql84/bin

# Chris' ruby stuff
export RUBYLIB=~/src/chrisbin/ruby
export RUBYOPT=rubygems
export PATH=$PATH:~/src/chrisbin:~/src/chrisbin/ruby

# I'm using java 1.6 on OSX
export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.6/Home

# manpath
export MANPATH=$MANPATH:/usr/local/man:/opt/local/share/man

# abbreviation
export EDITOR=vim
export PAGER=less

# CVS for HeX
export CVSROOT=:ext:dakrone@cvsup.rawpacket.org:/home/project/rawpacket/cvs

# RSPEC for autotest
export RSPEC=true

# Source j.sh
source ~/bin/j.sh

# Term settings, if we exist as a screen term, use xterm-color instead of screen-bce.
# Otherwise, leave the TERM var alone, because we need it to set terminal titles correctly
case $TERM in
      screen*)
            export TERM=xterm-color
      ;;
esac

# set aliases
alias mv='nocorrect mv'       # no spelling correction on mv
alias cp='nocorrect cp'
alias mkdir='nocorrect mkdir'
#alias j=jobs
if ls -F --color=auto >&/dev/null; then
  alias ls="ls --color=auto -F"
else
  alias ls="ls -GF"
fi
alias l.='ls -d .*'
alias ll='ls -lh'
alias la='ls -alh'
alias lr='ls -lR'
alias less='less -FRX'
alias grep='grep -i --color=auto'
alias egrep='egrep -i --color=auto'
alias cd..='cd ..'
alias ..='cd ..'
alias nsmc='cd ~/src/ruby/nsm-console'
alias serv='cat /etc/services | grep'
alias pg='ps aux | grep'
alias nl='sudo netstat -tunapl'
alias dmesg='sudo dmesg'
alias gv='cd /media/VAULT/'
alias remhex='ssh -i ~/.ssh/id_rawpacket dakrone@localhost -p 6666'
alias remblack='ssh -i ~/.ssh/id_rawpacket hinmanm@localhost -p 7777'
alias scsetup='sudo socat -d -d TCP4-listen:6666,fork OPENSSL:hexbit:443,cert=host.pem,verify=0'
alias scsetup2='sudo socat -d -d TCP4-listen:7777,fork OPENSSL:blackex:443,cert=host.pem,verify=0'
alias blackexprox='ssh -i ~/.ssh/id_rawpacket -ND 9999 hinmanm@localhost -p 7777'
alias blackprox='ssh -i ~/.ssh/id_rawpacket -ND 9999 hinmanm@black'
alias tcpdump='tcpdump -ttttnnn'
alias vless=/usr/share/vim/vim72/macros/less.sh
alias week='remind -c+1 ~/.reminders'
alias month='remind -c ~/.reminders'
alias flacsync='rsync -av --delete --ignore-existing ~/Music/FLAC/ /media/ALTHALUS/FLAC/'
alias musicsync='rsync -av --delete --ignore-existing ~/Music/Library/ /media/ALTHALUS/Library/'
alias gps='geektool-ps'
alias jl='j --l'
alias jr='j --r'
alias js='j --s'
alias givm='gvim'
# Colored rspec
alias cspec='spec -c --format specdoc'


# history
HISTFILE=$HOME/.zsh-history
HISTSIZE=5000
SAVEHIST=1000
setopt appendhistory autocd extendedglob
setopt share_history
function history-all { history -E 1 }


# functions
mdc() { mkdir -p "$1" && cd "$1" }
setenv() { export $1=$2 }  # csh compatibility
sdate() { date +%Y.%m.%d }
rot13 () { tr "[a-m][n-z][A-M][N-Z]" "[n-z][a-m][N-Z][A-M]" }
function maxhead() { head -n `echo $LINES - 5|bc` ; }
function maxtail() { tail -n `echo $LINES - 5|bc` ; }
function git_dirty_flag() {
  git status 2> /dev/null | grep -c : | awk '{if ($1 > 0) print "⚡"}'
}
function parse_git_branch() {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}


# prompt (if running screen, show window #)
if [ x$WINDOW != x ]; then
    # [5:hinmanm@dagger:~]% 
    export PS1="%{$fg[blue]%}[%{$fg[cyan]%}$WINDOW%{$fg[blue]%}:%{$fg[green]%}%n%{$fg[cyan]%}@%{$fg[green]%}%m%{$fg[blue]%}:%{$fg[magenta]%}%~%{$fg[blue]%}]%{$reset_color%}%# "
else
    # [hinmanm@dagger:~]% 
    export PS1="%{$fg[blue]%}[%{$fg[green]%}%n%{$fg[cyan]%}@%{$fg[green]%}%m%{$fg[blue]%}:%{$fg[magenta]%}%~%{$fg[blue]%}]%{$reset_color%}%# "
fi
export RPRMOPT="%{$reset_color%}"

# format titles for screen and rxvt
function title() {
  # escape '%' chars in $1, make nonprintables visible
  a=${(V)1//\%/\%\%}

  # Truncate command, and join lines.
  a=$(print -Pn "%40>...>$a" | tr -d "\n")

  case $TERM in
  screen*)
    print -Pn "\ek$a:$3\e\\"      # screen title (in ^A")
    ;;
  xterm-color*)
    print -Pn "\ek$a:$3\e\\"      # screen title (in ^A")
    ;;
  xterm*|rxvt)
    print -Pn "\e]2;$2 | $a:$3\a" # plain xterm title
    ;;
  esac
}

# precmd is called just before the prompt is printed
function precmd() {
  title "zsh" "$USER@%m" "%55<...<%~"

  # Print the regular prompt, or the lightning bolt if uncommitted git files
  #flag=`git_dirty_flag`
  #if [ -n "$flag" ]; then
    #export PS1="$PS1`git_dirty_flag`"
  #else
    #export PS1="$PS1%# "
  #fi
}

# preexec is called just before any command line is executed
function preexec() {
  title "$1" "$USER@%m" "%35<...<%~"
}

## For the "ZoomGo" ruby file
function zg () {
  eval cd `zg.rb $1`
}

# Make w/growl support
function gmake () {
  DIR=`pwd`
  make $1 $2 $3 $4 $5 $6 $7 $8 $9
  if [[ $? == 0 ]]; then
    growlnotify -m "'make $1' successful in $DIR" 
  else
    growlnotify -m "'make $1' failed in $DIR" 
  fi
}

# Configure w/growl support
function gconf () {
  DIR=`pwd`
  ./configure $1 $2 $3 $4 $5 $6 $7 $8 $9 
  if [[ $? == 0 ]]; then
    growlnotify -m "'configure' successful in $DIR" 
  else
    growlnotify -m "'configure' failed in $DIR" 
  fi
}

# colorful listings
zmodload -i zsh/complist
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' hosts $ssh_hosts
zstyle ':completion:*:my-accounts' users-hosts $my_accounts
zstyle ':completion:*:other-accounts' users-hosts $other_accounts

### OPTIONS ###
unsetopt BG_NICE		      # do NOT nice bg commands
setopt EXTENDED_HISTORY		# puts timestamps in the history
setopt NO_HUP                 # don't send kill to background jobs when exiting

# Keybindings
bindkey -e
bindkey "^?"    backward-delete-char
bindkey "^H"    backward-delete-char
bindkey "^[[3~" backward-delete-char
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line

bindkey '^r' history-incremental-search-backward
bindkey "^[[5~" up-line-or-history
bindkey "^[[6~" down-line-or-history
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^W" backward-delete-word
bindkey "^b" backward-word
bindkey "^f" forward-word
bindkey "^d" delete-word
bindkey "^k" kill-line
bindkey ' ' magic-space    # also do history expansion on space
bindkey '^I' complete-word # complete on tab, leave expansion to _expand

