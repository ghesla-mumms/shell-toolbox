#####
# When invoked as an interactive login shell, Bash executes commands found in
#   /etc/profile file
# then, executes the commands found in the first of the following files that exist...
#   ~/.bash_profile
#   ~/.bash_login
#   ~/.profile files
#
# When Bash is invoked as an interactive non-login shell, it reads and executes commands from ~/.bashrc, if that file exists, and it is readable.
#
# .bash_profile should contain
#   - environment variable settings
#   - a bit to run the .bashrc file if it exists
# .bashrc should contain
#   - alias and function definitions
#   - custom prompt
#   - custom history settings
#   - other ui stuff, etc.
#####

#####
# Environment variables
#####
export GIT_HOME=~/dev/hummingbird

# Java Switcher
export JAVA_7_HOME=$(/usr/libexec/java_home -v1.7)
export JAVA_8_HOME=$(/usr/libexec/java_home -v1.8)
export JAVA_11_HOME=$(/usr/libexec/java_home -v11)

# default java8
export JAVA_HOME=$JAVA_11_HOME

# HISTORY - Ignore duplicate commands in history, increase size
HISTCONTROL=ignoreboth:erasedups HISTSIZE=100000 HISTFILESIZE=200000

if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

test -e ~/.iterm2_shell_integration.bash && source ~/.iterm2_shell_integration.bash || true

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/g.hesla/opt/google-cloud-sdk/path.bash.inc' ]; then . '/Users/g.hesla/opt/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/g.hesla/opt/google-cloud-sdk/completion.bash.inc' ]; then . '/Users/g.hesla/opt/google-cloud-sdk/completion.bash.inc'; fi
