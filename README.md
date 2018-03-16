[![Gem Version](https://badge.fury.io/rb/itamae-spec.svg)](http://badge.fury.io/rb/itamae-spec)

Customized version of Itamae

## Concept

- Integration with Serverspec
- Attributes are defined by: Nodes, Environments, and Recipes
- Support for some AWS Resources
- Running on the RakeTask

## Installation

```
$ gem install itamae-spec
$ itamae-spec init your-project-name
```

## If you want to use the AWS Resources
```
$ aws configure
```

## Tips for git user
- Add this content to your `.gitignore`
```
tmp-nodes/
logs/
Project.json
!.keep
```

## Getting Started
- [Getting Started](https://github.com/kammy1231/itamae-spec/wiki/Getting-Started)

## Usage AWS Resource
- [Customized Resources](https://github.com/kammy1231/itamae-spec/wiki/Customized-Resources)

## Reference
- [itamae](https://github.com/itamae-kitchen/itamae)
- [Serverspec](https://github.com/mizzy/serverspec)

## Contributing

If you have a problem, please [create an issue](https://github.com/kammy1231/itamae-spec) or a pull request.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
