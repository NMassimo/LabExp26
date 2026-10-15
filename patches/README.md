# Course patch series

Base repository: https://github.com/openthread/ot-ns.git

Base commit: `1d61489561c22041b4877467c086721cfd0d2263`

`0001-configurable-radio-energy.patch` contains the radio consumption model,
profile, JSON CLI commands, Python methods, documentation, tests and example.
Apply it with:

```sh
python3 scripts/apply-patches.py
python3 scripts/apply-patches.py --check
```

The submodule HEAD stays at the upstream commit. The patch modifies its working
tree; these modifications are expected and are represented by this patch in
the course repository. The parent repository ignores submodule working-tree
dirtiness but still detects changes to the pinned commit. To inspect all changes:

```sh
git status --ignore-submodules=none
git -C otns diff
git -C otns ls-files --others --exclude-standard
```

Do not commit the patch into the OTNS submodule or use `git submodule update
--remote` for normal laboratory work.

## Updating the patch

Edit the selected files in `otns/`, then run:

```sh
python3 scripts/export-patch.py
./scripts/setup.sh
./scripts/check.sh
```

The exporter includes both modified upstream files and new files, without
changing the submodule index. If the implementation adds another source file,
include its path in `scripts/export-patch.py`. Review the generated diff before
committing it to the course repository. Test application on a fresh checkout
when changing the patch or upstream revision.

To update OTNS deliberately, review compatibility, update the submodule gitlink
and `otns.commit` together, regenerate the patch against that base and rerun the
checks. Keep these changes in one course-repository commit.
