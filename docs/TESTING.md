# Testing

Before opening a code review ensure the following use cases are successful locally.

## Singular

Reset machine following [./DEVELOPMENT.md](./DEVELOPMENT.md).

```sh
cd /root/of/project
git checkout ${NAME_OF_YOUR_FEATURE_BRANCH} --force
./libs/bash/install.sh
```

Should exit successfully.

## As an Upstream

Reset machine following [./DEVELOPMENT.md](./DEVELOPMENT.md).

```sh
cd /root/of/deployment_project
./libs/bash/install.sh ${NAME_OF_YOUR_FEATURE_BRANCH}
```

Should exit successfully.

## IAC module changes

Reset machine following [./DEVELOPMENT.md](./DEVELOPMENT.md).

```sh
cd /root/of/deployment_project
./libs/bash/install.sh ${NAME_OF_YOUR_FEATURE_BRANCH}

# Edit come IAC configuration
# vi terraform/aws/${SOME_ACCT}/path/to/module

git add .
git commit -m "Testing CI"
git push origin
```

Should exit successfully.
