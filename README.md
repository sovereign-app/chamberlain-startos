<p align="center">
  <img src="https://github.com/sovereign-app/chamberlain-startos/blob/master/.github/images/logo.png?raw=true" alt="sovereign.app Logo">
</p>

# Chamberlain for StartOS

[Chamberlain](https://github.com/sovereign-app/chamberlain) is a
[Cashu](https://cashu.space) mint built on
[CDK](https://github.com/cashubtc/cdk) with an integrated
[LDK](https://github.com/lightningdevkit/rust-lightning) Lightning Network node.

## Dependencies

Install the system dependencies below to build this project by following the
instructions in the provided links. You can find instructions on how to set up
the appropriate build environment in the
[Developer Docs](https://docs.start9.com/latest/developer-docs/packaging).

- [docker](https://docs.docker.com/get-docker)
- [docker-buildx](https://docs.docker.com/buildx/working-with-buildx/)
- [yq](https://mikefarah.gitbook.io/yq)
- [deno](https://deno.land/)
- [make](https://www.gnu.org/software/make/)
- [start-sdk](https://github.com/Start9Labs/start-os/tree/sdk/)

## Cloning

Clone the project locally:

```
git clone https://github.com/sovereign-app/chamberlain-startos.git
cd chamberlain-startos
git submodule update --init --recursive
```

## Building

To build the `chamberlain` package for all platforms using start-sdk, run the
following command:

```
make
```

To build the `chamberlain` package for a single platform using start-sdk, run:

```
# for amd64
make x86
```

or

```
# for arm64
make arm
```

## Installing (on StartOS)

Run the following commands to determine successful install:

> :information_source: Change server-name.local to your Start9 server address

```
start-cli auth login
# Enter your StartOS password
start-cli --host https://server-name.local package install chamberlain.s9pk
```

If you already have your `start-cli` config file setup with a default `host`,
you can install simply by running:

```
make install
```

> **Tip:** You can also install the chamberlain.s9pk using **Sideload Service**
> under the **System > Manage** section.

### Verify Install

Go to your StartOS Services page, select **Chamberlain**, configure and start
the service. Then, verify its interfaces are accessible.

**Done!**
