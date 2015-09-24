# 3CX Wallboard scrapper for Dashing

## Why it is needed?
3CX does not allow to show several queues information on one wallboard.
This script connects to 3CX wallboard using WebSockets and push data to Dashing using its API.

## How to run script
All fields in setting.yml file are self explanatory.
Please note that for every queue you should have separate service and settings file.
For Wallboard fields have a look here: http://www.3cx.com/blog/wallboard/ (<b>Available Queue Statistics</b> section).
Widgets itself are not attached, but you can push to (almost) any tipe of widget you like.
