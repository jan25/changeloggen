This is a test change.

# changeloggen ![ci-tests](https://github.com/jan25/changeloggen/workflows/ci/badge.svg)

Simple changelog generator for Github repositories. This cli tool works with **Github labels** attached to Pull requests to generate a markdown formatted changelog. It also provides a way to group by additional labels such as `Bug`, `Feature` etc.

## Install

WIP

## Features

``` bash
$ changeloggen --release=0.0.2 [--url=github.com/org/repo] [--labels=Feature, Bug] [--output=CHANGELOG]

# 0.0.2

## Feature
* New awesome feature (#12, @user)
* Another cool feature (#13, @user2)

## Bug
* Fix somethinng (#11, @user3)
* Fixed a bug (#10, @user1)
```

Note: Some of above options are WIP.
