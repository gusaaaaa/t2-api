#!/bin/bash
heroku run rake utilization:today -a t2api > doc/daily
sed -i -e '/DEPRECATION/d' ./doc/daily
sed -i -e '/Running/d' ./doc/daily
rm doc/daily-e
cat doc/daily | pbcopy

