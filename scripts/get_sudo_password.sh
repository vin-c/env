#!/bin/bash
/usr/bin/op read "op://Private/hlb3oe6y7escdbyga5nb64e2g4/password" | xargs -0 $(dirname $0)/set_clipboard_content.sh
