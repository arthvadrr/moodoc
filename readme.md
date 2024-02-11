# moodoc

This is a fork of the [moodle-docker](https://github.com/moodlehq/moodle-docker) repo from moodlehq. The purpose of
this project is to make it easy to spin up a version of moodle for
testing with a single command on docker. This was created out of
a general frustration of docker images not working properly, or missing
versions of moodle, or having missing configurations of their databases.

## the purpose of this project

This version of moodle-docker is meant for local testing of moodle.
This is not meant for server deployment.

The purpose is to strip the moodle-docker repo down to its bare bones - no external testing, no github actions, nothing
but what you need to spin up
versions on docker so you can test with a certain moodle instance.

## usage

Permissions need to be given to `./moodoc.sh` and the files in bin.
`chmod -u+x <filename>`

Run `./moodoc.sh help` for more options.

### `./moodoc.sh start <version>`

Starts the docker containers for this version of moodle.
If the moodle version isn't in the root directory, it will try to download it from moodlehq's github tagged releases.

### `./moodoc.sh stop <version>`

Stops the docker containers for this version of moodle without destroying the containers.

### `./moodoc.sh down <version>`

Stops the docker containers for this version of moodle and destorys the containers.
