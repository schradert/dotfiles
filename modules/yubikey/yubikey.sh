#!/usr/bin/env bash

ykinfo -s
ykman otp chalresp --touch --generate 2
ykpamcfg -2 -v
