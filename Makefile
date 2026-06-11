# Convenience targets for the terraform-aws-modules repo.
#
#   make fmt               # rewrite all HCL to canonical format
#   make fmt-check         # fail if any HCL is unformatted (CI-friendly)
#   make init              # terraform init -backend=false across modules + examples
#   make validate          # terraform validate across modules + examples
#   make examples-validate # init + validate only the examples/ configurations
#   make test              # alias for fmt-check + validate (CI test entrypoint)
#   make lint              # run tflint at the repo root
#   make clean             # remove .terraform dirs and lock files

# Directories that contain a root-level Terraform configuration.
MODULE_DIRS := \
	modules/vpc \
	modules/eks \
	modules/rds

EXAMPLE_DIRS := \
	examples/full-stack \
	examples/remote-state \
	examples/remote-state/bootstrap

TF_DIRS := $(MODULE_DIRS) $(EXAMPLE_DIRS)

.PHONY: fmt fmt-check init validate examples-validate test lint clean all

all: fmt-check validate lint

fmt:
	terraform fmt -recursive .

fmt-check:
	terraform fmt -recursive -check -diff .

# init/validate run per-dir with -backend=false so no remote backend is needed.
init:
	@set -e; for d in $(TF_DIRS); do \
		echo "==> init $$d"; \
		terraform -chdir=$$d init -backend=false -input=false -upgrade; \
	done

validate: init
	@set -e; for d in $(TF_DIRS); do \
		echo "==> validate $$d"; \
		terraform -chdir=$$d validate; \
	done

# examples-validate: init + validate the runnable examples only. Useful to
# confirm the published examples still wire the modules together correctly.
examples-validate:
	@set -e; for d in $(EXAMPLE_DIRS); do \
		echo "==> init $$d"; \
		terraform -chdir=$$d init -backend=false -input=false -upgrade; \
		echo "==> validate $$d"; \
		terraform -chdir=$$d validate; \
	done

# test: CI test entrypoint — formatting + full validate across modules+examples.
test: fmt-check validate

lint:
	@command -v tflint >/dev/null 2>&1 || { echo "tflint not installed; see https://github.com/terraform-linters/tflint"; exit 1; }
	tflint --recursive --config=$(CURDIR)/.tflint.hcl

clean:
	find . -type d -name ".terraform" -prune -exec rm -rf {} +
	find . -type f -name ".terraform.lock.hcl" -delete
