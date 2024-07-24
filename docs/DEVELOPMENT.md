# Development

## Reset locaLhost

```sh
vi ~/.bashrc
```

Remove all lines (inclusive) from `# WL GC Toolchain Management Starting` to `# WL GC Toolchain Management Ending`.

Next, remove tool cache directories.

```sh
rm -rf ~/.aqua/
rm -rf ~/.goenv/
rm -rf ~/.kics-installer/
rm -rf ~/.local/share/aquaproj-aqua/
rm -rf ~/.pyenv/
rm -rf ~/.terraform.d/*
rm -rf ~/.tofu*
sudo rm -rf ~/go
```

Start a new shell and output PATH.

```sh
echo $PATH
```

We expect to NOT see any of the configuration from the Toolchain. Specifically the PATH value should NOT include `.aqua` segments.

## Install Java

- https://docs.aws.amazon.com/corretto/latest/corretto-21-ug/amazon-linux-install.html
- https://docs.fedoraproject.org/en-US/quick-docs/installing-java/

