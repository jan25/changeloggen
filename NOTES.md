Changelog generator based on Github PR labels.

## Features

- Provide repository URL or make use of git config to automatically resolve repository URL
- A flag to supply release tag (label attached to PR)
- Grouping PRs by secondary labels(supplied from cli args)
- Simple formatter for a log: PR Title (#ID, #username)
- Output: dump to stdout or prepend to CHANGELOG file

```
> changeloggen --release=0.0.2 [--url=github.com/org/repo] [--labels=Feature, Bug] [--output=CHANGELOG]

# 0.0.2

## Feature
* New awesome feature (#12, @user)
* Another cool feature (#13, @user2)

## Bug
* Fix somethinng (#11, @user3)
* Fixed a bug (#10, @user1)
```

## Ideas

- Prepend or append to existing file
- Custom template for changelog
- Name for each label/tag (Feature -> Features)
- Save on github query by not getting all PRs ever made!
- Link to PR and user profile in output markdown