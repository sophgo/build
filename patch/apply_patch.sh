#!/bin/bash


apply_patches() {
      #echo "Applying patch: demo.patch"
      #git apply "build/patch/demo.patch" --directory="repo_dir"
}

revert_patches() {
     # echo "Reverting patch: demo.patch"
     # git apply -R "build/patch/demo.patch" --directory="repo_dir"
}

if [[ "$1" == "-p" ]]; then
  apply_patches
elif [[ "$1" == "-r" ]]; then
  revert_patches
else
  echo "Usage: source build/patch.sh [-p|-r]"
  echo "-p: Apply patches"
  echo "-r: Revert patches"
fi

