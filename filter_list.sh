#!/bin/bash
for source_package in $(cat ../pbuilder/list); do
  search_result=$(reprepro list unstable | grep source | grep "${source_package}" | awk '{print $2}')
  search_result_line=$(echo $search_result | wc -w)
  if [[ ${search_result_line} -gt 1 ]]; then
    echo "${source_package}'s search result is ${search_result}"
  elif [[ -z ${search_result_line} ]]; then
    echo "${source_package} no result"
  fi
done
