#!/usr/bin/env bash

set -o errexit
set -o allexport
__dirname=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
__root=${__dirname}
if [[ -f "${__root}/.env" ]]; then source "${__root}/.env"; fi
source "${__root}/shared/rm_helpers.sh" # ensure_group
set +o allexport

# setup supporting services
bash "${__root}/setup_infra.sh"

# setup proxy
bash "${__root}/setup_app.sh" \
    gomods/athens/proxy dev \
    no_cd \
    update_submodules_first \
    "https://github.com/gomods/athens.git" \
    proxy
bash "${__root}/configure_app.sh" proxy

# setup olympus
bash "${__root}/setup_app.sh" gomods/athens/olympus dev \
    no_cd \
    update_submodules_first \
    "https://github.com/gomods/athens.git" \
    olympus
bash "${__root}/configure_app.sh" olympus

