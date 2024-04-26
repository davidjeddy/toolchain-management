# Development

## Reset locaLhost

```sh
vi ~/.bashrc
```

Remove all references to aqua, goenv, and pyenv

```sh
rm -rf ~/.aqua/
rm -rf ~/.goenv/
rm -rf ~/.kics-installer/
rm -rf ~/.pyenv/
rm -rf ~/.local/share/aquaproj-aqua/
source ~/.bashrc
```

You are now reset to non-aqua configuration.
