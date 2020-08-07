<p align="center">
  <img src="https://raw.githubusercontent.com/amazeeio/lagoon/master/docs/images/lagoon-logo.png" alt="The Lagoon logo is a blue hexagon split in two pieces with an L-shaped cut" width="40%">
</p>

# Lagoon Base Images

This repository contains [Dockerfiles](https://docs.docker.com/engine/reference/builder/) related to [Lagoon](https://github.com/amazeeio/lagoon/).

This repository was created with `git filter-repo` from the main Lagoon repository, in order to preserve commit history.

## Usage

These dockerfiles are used to create the base images for consumption in [Docker Compose](https://docs.docker.com/compose/) based projects.

The images used to build Lagoon itself are stored in the Lagoon repository, and are built separately.

## Contribute

Branch/fork and add/edit a Dockerfile in the `images/` directory.

### Makefile

This project utilises a Makefile to build and test images.

Once you have made a modification to a base image, follow these steps to rebuild the images, start a local Lagoon stack from tagged images, and run the predefined tests through a local Kubernetes stack.

```
make build

make up

make k8s-tests
```

Note that only a few tests are currently provided (NGINX and Drupal) - if you'd like to contribute more, please reach out!