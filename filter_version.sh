#!/bin/bash
mirrors="https://mirrors.sjtug.sjtu.edu.cn/debian"
framework=$1
if [[ ${framework:0:3} = lib ]]; then
  framework_first_word="${framework:0:4}"
else
  framework_first_word="${framework:0:1}"
fi
framework_url="${mirrors}/pool/main/${framework_first_word}/${framework}"
framework_dsc=$(curl --silent ${framework_url}/ | grep dsc | awk -F '"' '{print $2}'| sort --sort=version |  awk 'END {print}')
framework_version=$(echo ${framework_dsc} | awk -F '_' '{print $2}' | awk -F '-' '{print $1}' | sort --sort=version)
echo "${framework}: ${framework_version}"
