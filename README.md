# dockerized_terraform

a wrapper script for Dockerized Terraform

This is a wrapper script for running Terraform in a Dockerized
environment.  Therefore, this script requires only that Docker
be usable and accessible by the user -- Terraform does not need
to be installed on the local system.

Additionally, once `terraform` has been run (in the container),
then it will cleanup after itself and reset the ownership of
newly-created files to the current user's UID and GID (by
default).

## Working Directory

Because `terraform` needs to be able to read files (e.g., ".tf"
files), we need a way to get those files into the Dockerized
environment.  The simple way to do this is to mount the current
directory into the container; however, there are times when
that doesn't work.  For example, in one project, we keep files
specific to a tier in a separate directory tree than modules
used by tier-specific files.  Therefore, some mangling may be
required.

The recommended approach is to run the wrapper script from
a location common to all files needed to run properly and
to reference said files using relative paths.  For example,

Suppose the following:

```
.
├── environments
│   ├── dev
│   │   └── main.tf
│   ├── prod
│   │   └── main.tf
│   └── staging
│       └── main.tf
└── modules
    ├── module1
    │   └── main.tf
    └── module2
        └── main.tf
```

instead of:

```shell
cd environments/dev ; tf apply main.tf
```

use this:

```shell
tf apply environments/dev/main.tf
```

## Variables

### TFIMAGE

`TFIMAGE` is the image to use to run `terraform`; the default is `hashicorp/terraform:light`

### CLEANUPIMAGE

`CLEANUPIMAGE` is the image to use to perform the "cleanup" (i.e., `chown`); the default is `busybox:latest`

### PROJECT_ROOT

`PROJECT_ROOT` is the directory to mount to the container; the default is the current working directory

### WORKDIR

`WORKDIR` is the location in the container where `PROJECT_ROOT` will be mounted; the default is `/workdir`

### TIMESTAMPFILE

`TIMESTAMPFILE` is the name of the file used to track the time when `terraform` is started so that `find` may
determine which files have been modified since `terraform` ran and `chown` them back to the current user.
This file is created before `terraform` runs and is removed after `terraform` is completed.

### uid

`uid` is the numeric uid to pass to `chown`; this UID doesn't need to exist in either container; however, the
NUMERIC UID must be used (the containers can't map user names to numeric UIDs); the default is the current
user's effetive UID.

### gid

`gid` is just like `uid`, but for group IDs (GIDs).  This GID doesn't need to exist in the containers, as
with `uid`, but only the NUMERIC GIDs may be used; default is the current user's effective GID.

## AWS Credentials

If the current user has AWS credentials stored on the local filesystem (i.e., `~/.aws/credentials`), then
those credentials are mounted to the containers at `/root/.aws/credentials`.

## Rewriting Directories

When `terraform` runs in a container, messages include directories and locations may be displayed; however,
they are relative to the root of the container, not the user's filesystem.  Therefore, `sed` is used to
rewrite the output so that the WORKDIR is translated to PROJECT__ROOT.

For example, if the wrapper is run from `/home/user/src` and the WORKDIR is `/workdir` then

`/workdir/main.tf` is rewritten to read `/home/user/src/main.tf`.
