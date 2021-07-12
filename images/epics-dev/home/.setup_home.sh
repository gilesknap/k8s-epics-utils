#!/bin/bash

echo """
[user]
	email = ${EMAIL}
	name = ${FULLNAME}
[core]
	editor = vim
""" > ${HOME}/.gitconfig

sed -e "s|HOME_DIR|${HOME}|" -i ${HOME}/.kube/config

echo source ~/.bashrc_local >> ~/.bashrc
