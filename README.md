# changeloggen ![ci-tests](https://github.com/jan25/changeloggen/workflows/ci/badge.svg)

Simple changelog generator for Github repositories. This cli tool fetches changes after latest release tag to generate a markdown formatted changelog. It also provides a option to group by additional labels attached to PR such as `Bug`, `Feature` etc.

## Install

WIP

## Usage

``` bash
$ changeloggen --help

$ changeloggen [--release=0.2.0] [--url=github.com/org/repo] [--labels=Feature,Bug]

# 0.2.0

## Feature
* New awesome feature (#12, @user)
* Another cool feature (#13, @user2)

## Bug
* Fix somethinng (#11, @user3)
* Fixed a bug (#10, @user1)
```
