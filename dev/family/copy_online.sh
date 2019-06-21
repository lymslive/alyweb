#!/bin/bash

# CP=cp -vu
DEV=.
SVR=../../family

cp -vu $DEV/Family*.pm $SVR/
cp -vu $DEV/japi.* $SVR/
cp -vu $DEV/*.pl $SVR/
cp -vu -r $DEV/web/* $SVR/web/
cp -vu -r $DEV/doc/* $SVR/doc/
cp -vu -r $DEV/sql/* $SVR/sql/
