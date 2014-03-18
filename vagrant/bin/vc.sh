#!/bin/bash
cwd=$1
command=$2
length=$(($#))
args=${@:3:$length}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $(pgrep -f "vagrant@arroyo.local") > 0 ]; then
  ssh -i ~/.vagrant.d/insecure_private_key vagrant@arroyo.local -F $DIR/../vssh-config "cd $cwd; $command $args";
else
  ssh -MNf -i ~/.vagrant.d/insecure_private_key vagrant@arroyo.local -F $DIR/../vssh-config && ssh -i ~/.vagrant.d/insecure_private_key vagrant@arroyo.local -F $DIR/../vssh-config"cd $cwd; $command $args";
fi
