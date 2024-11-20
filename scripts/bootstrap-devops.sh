#!/bin/bash

dnf install -y poetry dnf-plugins-core

dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo

dnf -y install terraform