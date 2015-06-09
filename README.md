# dev-config

## Synopsis

Collection of personal config scripts for development 

## Details

**init.el** - Emacs config file
***
**bootstrap.ps1** - Windows configuration script

This script will install my softwares and configure windows to fit my needs. It can be used to bootstrap a pc from scratch by executing:

`@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/Shonallein/dev-config/master/bootstrap.ps1'))"`

The same command can be executed on an existing environment. In this case, the script will only add the missing component to it.
***

