#!/bin/bash

set -e

bundle exec je puma -I lib -p ${PORT:-80} -t ${PUMA_MIN_THREADS:-8}:${PUMA_MAX_THREADS:-12} -w ${PUMA_WORKERS:-2}
