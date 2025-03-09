#!/bin/bash

mkdir -p deb/opt/vds-games/connecman
cp *.rb deb/opt/vds-games/connecman/
cp -r data deb/opt/vds-games/connecman/
dpkg -b deb connecman-1.1.2.deb
