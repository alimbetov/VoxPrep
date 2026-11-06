#!/usr/bin/env bash
# Source this file in the shell used for Maven. No global SDK settings change.
export JAVA_HOME="$(/usr/libexec/java_home -v 21)"
export PATH="$JAVA_HOME/bin:$PATH"
