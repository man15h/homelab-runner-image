# ansible-sops-runner

A job-container image for Gitea and Forgejo Actions runners. Every step of a
workflow on such a runner executes inside its job container, so this image
ships a deploy toolchain ready to use: SOPS, Ansible, Python 3 with venv,
OpenSSH client, git and jq, on `debian:bookworm-slim`. Tool versions are
pinned by `ARG` at the top of the `Dockerfile`.

This is *not* the runner itself. The runner is upstream `gitea/act_runner`
(or Forgejo's `runner`), which pulls this image to create a container per job.

## Using it

Point a runner label at the image in the runner's config:

```yaml
runner:
  labels:
    - "ubuntu-deploy:docker://ghcr.io/<owner>/<repo>:<version>@sha256:<digest>"
```

Jobs with `runs-on: ubuntu-deploy` then run inside it. The image has no
Node runtime, so JavaScript actions such as `actions/checkout` don't run in
it; fetch the repo with plain `git` instead.

## Build and publish

Images are built only when a change lands on `main`. Pull requests don't
build, and there is no manual trigger. A merge that touches the `Dockerfile`
makes `.github/workflows/build.yml` do three things:

1. Bump the patch version from the highest `vX.Y.Z` tag. The first
   release is `v0.1.0`.
2. Build `linux/amd64` and `linux/arm64` (arm64 under QEMU) and push
   `ghcr.io/<owner>/<repo>` as `<version>`, `latest` and `sha-<commit>`.
3. Push the `v<version>` git tag.

The built-in `GITHUB_TOKEN` does the push, so no secret is needed.

## Pinning

Pin a version and its digest, not `:latest`. The workflow run's job summary
prints the full reference:

```
ghcr.io/<owner>/<repo>:<version>@sha256:<digest>
```

Repinning should stay a manual step: an image build should not be able to
change what runs in CI without a human in the loop.

**If several runner labels use this image, repin one at a time.** A bad image
pinned everywhere takes out all CI at once, including any job that would
publish the fix. Move one label, confirm a green job, then move the rest.

**Rollback** is the same edit with the previous reference. If every label is
already broken, edit the runner's config on its host and restart it, then
fix forward through CI.

## Local build

```sh
docker build -t ansible-sops-runner:local .
```

The `Dockerfile`'s last `RUN` checks every installed tool, so a broken tool
version fails the build rather than shipping.
