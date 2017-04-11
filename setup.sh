#!/usr/bin/env bash

OS=$(uname -s)
if [[ "$OS" == "Darwin" ]]; then
    if brew ls --versions openssl > /dev/null; then
        echo "Detected $OS..."
        echo "Setting needed ENV to build psycopg2..."
        export LDFLAGS="-L/usr/local/opt/openssl/lib"
        export CPPFLAGS="-I/usr/local/opt/openssl/include"
        export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"
    fi
fi

#######################
#  Dependency Checks  #
#######################

cmd_list=('ruby' 'bundle' 'virtualenv' 'vagrant')

# Function to check if referenced command exists
cmd_exists() {
  if [ $# -eq 0 ]; then
    echo 'WARNING: No command argument was passed to verify exists'
  fi

  cmd=${1}
  hash "${cmd}" >&/dev/null # portable 'which'
  rc=$?
  if [ "${rc}" != "0" ]; then
    echo "Unable to find ${cmd} in your PATH"
    return 1
  fi
}

# Verify that referenced commands exist on the system
for cmd in ${cmd_list[@]}; do
  cmd_exists "$cmd"
done

#######################
#  Library Functions  #
#######################

run() {
    "$@"
    rc=$?
    if [[ $rc -gt 0 ]]; then
        return $rc
    fi
}

#######################
echo " -------------------------------------------------------------------"
echo "|                                                                   |"
echo "| You should be running this with "source ./setup.sh"                 |"
echo "| Running this directly like:                                       |"
echo "| * ./setup.sh                                                      |"
echo "| * bash ./setup.sh                                                 |"
echo "| Will fail to set certain environment variables that may bite you. |"
echo "|                                                                   |"
echo "|                                                                   |"
echo "| Waiting 5 seconds for you make sure you have ran this correctly   |"
echo "| Cntrl-C to bail out...                                            |"
echo "|                                                                   |"
echo " -------------------------------------------------------------------"

for n in {5..1}; do
  printf "\r%s " $n
  sleep 1
done

ruby_version=$(ruby --version | awk '{print $2}' | cut -d. -f1)
if [[ "${ruby_version}" -lt 2 ]]; then
    echo 'You need a version of ruby > 2 to run tests.'
    echo 'Upgrade your ruby (or use rbenv/rvm/ruby-install) and come back.'
    return 1
fi

if [ ! -d ./.venv ]; then
    echo "Failed to find a virtualenv, creating one."
    run virtualenv ./.venv
else
    echo "Found existing virtualenv, using that instead."
fi

# shellcheck disable=SC1091
. ./.venv/bin/activate
run pip install --upgrade pip
run pip install --upgrade setuptools
run pip install -r requirements.txt
run bundle install --path ./.vendor/bundle
run ansible-galaxy install -r requirements.yml -p galaxy_roles -f

# Now, we need to set it so that we can use bundle exec from anywhere
export BUNDLE_GEMFILE="$(pwd)/Gemfile"

# We also want to unset this when we run deactivate, but virtualenv provides that function.
# We'll need to overwrite it here and export it

deactivate () {
        unset -f pydoc > /dev/null 2>&1
        if ! [ -z "${_OLD_VIRTUAL_PATH+_}" ]
        then
                PATH="$_OLD_VIRTUAL_PATH"
                export PATH
                unset _OLD_VIRTUAL_PATH
        fi
        if ! [ -z "${_OLD_VIRTUAL_PYTHONHOME+_}" ]
        then
                PYTHONHOME="$_OLD_VIRTUAL_PYTHONHOME"
                export PYTHONHOME
                unset _OLD_VIRTUAL_PYTHONHOME
        fi
        if [ -n "${BASH-}" ] || [ -n "${ZSH_VERSION-}" ]
        then
                hash -r 2> /dev/null
        fi
        if ! [ -z "${_OLD_VIRTUAL_PS1+_}" ]
        then
                PS1="$_OLD_VIRTUAL_PS1"
                export PS1
                unset _OLD_VIRTUAL_PS1
        fi
        unset VIRTUAL_ENV
        unset BUNDLE_GEMFILE
        if [ ! "${1-}" = "nondestructive" ]
        then
                unset -f deactivate
        fi
}


if [ "$ZSH_VERSION" ]; then
    autoload -Uz deactivate
else
    export -f deactivate
fi

echo " ----------------------------------------------------------------------------"
echo "|                                                                            |"
echo "| You are now within a python virtualenv at ./.venv                          |"
echo "| This means that all python packages installed will not affect your system. |"
echo "| To return _back_ to system python, run deactivate in your shell.           |"
echo "|                                                                            |"
echo " ----------------------------------------------------------------------------"
