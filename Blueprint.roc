# Development environment and tasks for roc-pandoc, realised by roc-blueprint without Nix.
#
#     blueprint run check      # everything the release workflow checks before packaging
#     blueprint run goldens    # the golden tests alone; add `-- --update` to re-record them
#     blueprint shell          # the environment, to run scripts/*.roc directly
#     blueprint update         # refresh Blueprint.lock
#
# `roc-stable` runs repository scripts; `roc` on PATH checks the package, the
# examples and the golden tests on the latest nightly, so nothing here provides
# a bare `roc`. Building, testing and publishing a release is the shared
# roc-automation workflow that .github/workflows/release.yml calls; it runs the
# `check` task here. `pandoc` is expected on PATH for the golden tests and the
# directory examples.
app [config] { pf: platform "https://github.com/lukewilliamboswell/roc-blueprint/releases/download/0.8.0/FbJymjYdCxx9vqMcau7r4tQfeAbnVGqqJoYrLGqPCqKu.tar.zst" }

import pf.Recipes

config = [
	Name("roc-pandoc"),
	Systems(["x86_64-linux", "aarch64-linux", "aarch64-darwin"]),
	Environment(
		"dev",
		[
			Programs([Fetch("roc-stable", Recipes.roc_nightly("nightly-2026-09-10-a670e34"))]),
			# Programs the scripts start.
			Expect(["git", "pandoc", "roc", "unzip"]),
		],
	),
	# The shared release workflow runs this utility against the `roc` on PATH; a
	# maintainer runs the same task locally, such as `-- test-examples --update`.
	Environment("release", [Programs([Fetch("release-package", Recipes.file("https://github.com/lukewilliamboswell/roc-automation/releases/download/tools-0.6.0/release-package-{system}"))]), Expect(["roc", "git", "gh", "pandoc", "tar", "unzip", "zip", "chmod", "touch", "env"])]),
	Shell("default", [Use("dev")]),
	# Everything checked before the release workflow packages anything.
	Task("check", [Use("dev"), Run(["scripts/check_all.roc"])]),
	Task("release-package", [Use("release"), Run(["release-package"])]),
	# The golden tests of tests/cases against tests/goldens.
	Task("goldens", [Use("dev"), Run(["scripts/test_goldens.roc", "--"])]),
]
