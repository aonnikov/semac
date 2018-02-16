#!/bin/bash

# Some constants to bring more color to our life
RESET='\033[0m'
BOLD='\033[1;39m'
GREEN='\033[1;32m'
RED='\033[1;31m'

ohai() {
    echo -e "${GREEN}==>${BOLD} $1${RESET}"
}

warn() {
    echo -e "${RED}Warning${RESET}: $1"
}

append_to_file() {
  local file="$1"
  local text="$2"

  if ! grep -qs "^$text$" "$file"; then
    printf "\n%s\n" "$text" >> "$file"
  fi
}

greeting()
{
    echo -e "This script will help you to prepare your Mac to development."
    echo -e "What does it install:"
    echo -e " - Homebrew"
    echo -e " - Oracle JDK 8"
    echo -e " - Maven"
    echo -e " - iTerm2 & Oh My Zsh"
    echo -e " - IntelliJ IDEA CE"
    echo
    echo -n "Press RETURN to continue or Ctrl+C to exit..."
    read -r
}

farewell()
{
    echo -e "Installation is completed. Well done!"
    echo
    echo -e "Now you can close the terminal and launch iTerm2!"
}

greeting

############################################################################
# Homebrew Setup
############################################################################

SHELL_FILE="$HOME/.bashrc"

if ! command -v brew >/dev/null; then
    ohai "Installing Homebrew..."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    # shellcheck disable=SC2016
    append_to_file "$SHELL_FILE" 'export PATH="/usr/local/bin:$PATH"'
else
    ohai "Homebrew already installed."
fi

ohai "Updating Homebrew..."
cd "$(brew --repo)" && git fetch && git reset --hard origin/master && brew updates

ohai "Verifying the Homebrew installation..."
if brew doctor; then
  ohai "Homebrew installation is good."
else
  warn "Your Homebrew installation reported some errors or warnings."
  warn "Review the Homebrew messages to see if any action is needed."
fi

############################################################################
# Homebrew casks and formulas Setup
############################################################################

brewapps=(
    git
    ksh
    wget
)
ohai "Installing Homebrew formulas..."
brew install "${brewapps[@]}"

ohai "Installing Cask..."
brew tap caskroom/cask
brew tap caskroom/versions

ohai "Installing Applications..."
caskapps=(
    iterm2
    visual-studio-code
)
brew cask install --appdir="/Applications" "${caskapps[@]}"

ohai "Installing Oh My Zsh..."
# Using batch-mode branch instead of master to be able install Oh My Zsh in a script
# See https://github.com/robbyrussell/oh-my-zsh/pull/5893
# https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/loket/oh-my-zsh/feature/batch-mode/tools/install.sh)" -s --batch || {
  warn "Could not install Oh My Zsh"
}

SHELL_FILE="$HOME/.zshrc"
# shellcheck disable=SC2016
append_to_file "$SHELL_FILE" 'export PATH="/usr/local/bin:$PATH"'

# Add autocomplete reinitialization fix
append_to_file "$SHELL_FILE" '# Manually reinitialize completion'
append_to_file "$SHELL_FILE" 'rm -f ~/.zcompdump; compinit -u'
ohai "Added fix for Oh My Zsh autocompletion initialization."

# shellcheck disable=SC2016
append_to_file "$SHELL_FILE" 'code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}'
ohai "Added VS Code alias."

############################################################################
# Java Development Setup
############################################################################

ohai "Setup for Java Development? [y/N]"
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    ohai "Installing Oracle JDK 8..."
    if ! /usr/libexec/java_home -v 1.8;
    then
        brew cask install java8
        append_to_file "$SHELL_FILE" "alias use-java-8='export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)'"
    else
        ohai "Oracle JDK 8 already installed."
        append_to_file "$SHELL_FILE" "alias use-java-8='export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)'"
    fi

    append_to_file "$SHELL_FILE" "use-java-8"

    ohai "Installing Maven..."
    brew install maven

    ohai "Do you want to IntelliJ IDEA Community Edition? [y/N]"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        ohai "Installing IntelliJ IDEA Community Edition..."
        brew cask install caskroom/cask/intellij-idea-ce
    fi

    ohai "Java Development Setup Completed!"
fi

############################################################################
# Ruby Development Setup
############################################################################

ohai "Setup for Ruby Development? [y/N]"
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # Install rvm
    ohai "Installing RVM..."
    command curl -sSL https://get.rvm.io | bash -s stable
    # shellcheck source=/dev/null
    . ~/.rvm/scripts/rvm

    ohai "Installing Rubies..."
    rvm install 1.9
    rvm install 2.3

    # Check installed rubies
    rvm list

    gem install bundler
    ohai "Ruby Development Setup Completed!"
fi

############################################################################
# Cleanup
############################################################################

ohai "Cleaning Up Brew & Cask Files..."
brew cleanup
brew cask cleanup

farewell
