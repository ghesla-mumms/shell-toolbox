#####
# Environment variables
#####

##########
# Aliases
##########

alias dateutc='echo "{TZ=UTC date}" && TZ=UTC date'
alias utcdate='echo "{TZ=UTC date}" &&TZ=UTZ date'

# OpenShift aliases
alias ocl='echo "{oc logs -f}" && oc logs -f'
alias ocp='echo "{oc get pods}" && oc get pods'
alias ocpr='echo "{oc get projects}" && oc get projects'
alias ocpro='echo "{oc project}" && oc get project'

# launch mirth application
alias mirth="/Applications/Mirth\ Connect\ Administrator\ Launcher/launcher"

# Colorized ls(?)
ls --color=al > /dev/null 2>&1 && alias ls='ls -F --color=al' || alias ls='ls -G'
alias latr='ls -latr'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'

# Java switcher (env variables are set in .bash_profile
alias java7='echo "Setting JAVA_HOME to $JAVA_7_HOME" && export JAVA_HOME=$JAVA_7_HOME'
alias java8='echo "Setting JAVA_HOME to $JAVA_8_HOME" && export JAVA_HOME=$JAVA_8_HOME'
alias java11='echo "Setting JAVA_HOME to $JAVA_11_HOME" && export JAVA_HOME=$JAVA_11_HOME'

# grep shortcut
alias gr='grep -rnwli ./ -e'

# GIT aliases
alias gdif='echo "{git dif}" && git diff'
alias gstat='echo "{git status}" && git status'
alias gsta='echo "{git status}" && git status'
alias gadd='echo "{git add}" && git add'
alias gitmer='echo "{git merge --no-ff --no-commit}" && git merge --no-ff --no-commit'
function pimmer() {
  echo "{gitmer origin/stories/$1/story}"
  git merge --no-ff --no-commit origin/stories/$1/story
  git status
}
# PROMPT
# PS1='\h:\W \u\$ '
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
export PS1="\u@\h \[\e[32m\]\w \[\e[91m\]\$(parse_git_branch)\[\e[00m\]$ "
