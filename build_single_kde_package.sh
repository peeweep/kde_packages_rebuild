#!/bin/bash
set -x
mirrors="https://mirrors.sjtug.sjtu.edu.cn/debian"
framework=$1
if [[ ${framework:0:3} = lib ]]; then
  framework_first_word="${framework:0:4}"
else
  framework_first_word="${framework:0:1}"
fi
framework_url="${mirrors}/pool/main/${framework_first_word}/${framework}"
framework_dsc=$(curl --silent ${framework_url}/ | grep dsc | awk -F '"' '{print $2}' | sort --sort=version | awk 'END {print}' | sed 's|%2B|+|')
framework_version=$(echo ${framework_dsc} | awk -F '_' '{print $2}' | awk -F '-' '{print $1}' | sed 's|.dsc$||')
source_dir="${HOME}/peeweep/pbuilder/source"
framework_source_dir=${framework}-${framework_version}
basetgz=$(echo ${HOME}/peeweep/pbuilder/ppa.tgz)
pbuilder_result="${HOME}/peeweep/pbuilder/build"
kwin_ppa="${HOME}/peeweep/kwin-ppa"
mutt_config="${HOME}/peeweep/nvchecker.muttrc"
if [ ! -d ${source_dir} ]; then
  mkdir -pv ${source_dir}
fi

echo_success() {
  echo $framework >>${source_dir}/success_list
}
echo_failed() {
  echo ${framework} >>${source_dir}/failed_list
  if [ -f ${mutt_config} ]; then
    echo "${framework} failed" | neomutt -s "Alert for kwin update" peeweep@0x0.ee -F ${mutt_config} -a ${source_dir}/${framework}.log
  fi
}

cd ${source_dir}

if [ $framework_version ]; then
  dget ${framework_url}/${framework_dsc}
  if [ -d ${framework_source_dir} ]; then
    rm -rf ${framework_source_dir}
  fi
  dpkg-source -x --skip-patches ${framework_dsc}

  cd ${source_dir}/${framework_source_dir}/

  # downgrade debhelper
  if [[ $(cat debian/control | grep 'debhelper (>= 13') ]]; then
    sed -i 's|debhelper (>= 13|debhelper (>= 12|' debian/control
  elif [[ $(cat debian/control | grep 'debhelper (>= 13') ]]; then
    sed -i 's|debhelper (= 13|debhelper (= 12|' debian/control
  elif [[ $(cat debian/control | grep 'debhelper-compat (= 13') ]]; then
    sed -i 's|debhelper-compat (= 13|debhelper-compat (= 12|' debian/control
  elif [[ $(cat debian/control | grep 'debhelper-compat (>= 13') ]]; then
    sed -i 's|debhelper-compat (>= 13|debhelper-compat (>= 12|' debian/control
  fi

  # generate dsc
  dpkg-source -b .

  cd ${source_dir}
  # clean last result
  sudo rm -rfv /var/cache/pbuilder/result/*
  # update basetgz
  sudo pbuilder --update --basetgz ${basetgz}
  # build basetgz
  sudo pbuilder --build --basetgz ${basetgz} ${source_dir}/${framework_dsc} 2>&1 | tee ${source_dir}/${framework}.log
  # move result
  if [[ $(ls /var/cache/pbuilder/result/) ]]; then
    echo_success
    rm -v ${source_dir}/${framework}.log
    if [ -d ${pbuilder_result} ]; then
      rm -rfv ${pbuilder_result}
    fi
    mkdir -pv ${pbuilder_result}
    sudo mv /var/cache/pbuilder/result/* ${pbuilder_result}/ -v
    sudo mv ${source_dir}/${framework}_* ${pbuilder_result}/ -v
    rm -rf ${source_dir}/${framework_source_dir}

    cd ${kwin_ppa} || exit
    if [[ $(find ${pbuilder_result} -name '*.dsc') ]]; then
      find ${pbuilder_result}/*.dsc | xargs -I{} reprepro includedsc unstable {}
    fi
    if [[ $(find ${pbuilder_result} -name '*.deb') ]]; then
      reprepro includedeb unstable ${pbuilder_result}/*.deb
    fi
    if [[ $(find ${pbuilder_result} -name '*.udeb') ]]; then
      reprepro includeudeb unstable ${pbuilder_result}/*.udeb
    fi
  else
    echo_failed
    # rm -rf ${source_dir}/${framework_source_dir}
    # rm -rfv ${source_dir}/${framework}_*
  fi
else
  echo_failed
fi
