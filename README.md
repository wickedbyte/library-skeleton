# PHP Library Skeleton

Run `make` to build the project Docker image, create the "./build" cache directory
and install vendor dependencies with Composer.

To upgrade the project dependencies to their current major versions, run `make upgrade`, or
to just update them within the bounds of their currently defined constraints, run `make update`

Common Actions with Makefile targets:
 - `make bash`
 - `make phpunit`
 - `make phpcs`
 - `make phpcbf`
 - `make phpstan`
 - `make rector`
 - `make rector-dry-drun`
 - `make ci`

To get a fresh start, run `make clean` to delete the vendor and build directories,
which will trigger a docker image rebuild, the next time `make` or `make build` is run.

For anything else not defined in the Makefile, use:
```shell
docker compose run --rm -it app {your-command-here}
```
