# My Git utils

Some usefull git utils

## Local git repository storage

Manage git repository backups as TGZ file with INFO metadata. For each repository create
two files `reponame.git.tgz` and `reponame.git.info`. In `*.git.info` stored metadata in
plain text format.

For example `SDL.git.info`:
```
DESC=Simple DirectMedia Layer (SDL) Version 3.0
REPO=https://github.com/libsdl-org/SDL.git
FILE=SDL.git.tgz
MD5=bead0405e9b59abdc7a07d3c54c9957d
ORIGSIZE=232284015
```

Programs list:
- `gitclone.sh` - create tgz/info from remote repository by `git clone` command in `/dev/shm`.
- `gitupdate.sh` - refresh content of tgz/info file with `git pull` and `git fetch --prune` for synchronize data.
- `gitarch.sh` - make tgz/info from local directory with git repository

TODO: make web interface for that

## Useful utilities

- `gitfh` - make git file history as patch file and open it in `mcedit`, useful in rebase process to make difficult investigations
- `gitrs` - make backup of "both modified" files in rebase conflict (if something going wrong).
