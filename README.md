# changeloggen ![ci-tests](https://github.com/jan25/changeloggen/workflows/ci/badge.svg)

Simple changelog generator for Github repositories. This cli tool uses PRs after latest release tag to generate a markdown formatted changelog. It also provides a option to group by additional labels attached to PR such as `Bug`, `Feature` etc.

## Install

Make sure to have [Erlang and Elixir](https://elixir-lang.org/install.html#distributions) local installations.

Clone this repository and use `mix` to build and run this tool.
```bash
$ cd path/to/changeloggen
$ mix escript.build
$ ./changeloggen --help
```

WIP: Publish to hex.pm so installing using `mix escripts.install changeloggen` is possible.

## Usage

``` bash
$ changeloggen --help

$ changeloggen [--release=0.2.0] [--url=github.com/org/repo] [--labels=Feature,Bug]

# 0.2.0

## Feature
* New awesome feature (#12, @honey)
* Another cool feature (#13, @badger)

## Bug
* Fix somethinng (#11, @honeybadger)
* Fixed a bug (#10, @fearless)
```
