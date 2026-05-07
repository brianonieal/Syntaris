---
name: rollback
description: Revert a Syntaris project to the last closed gate. Use this skill when a completed gate turns out to be wrong (bad architectural decision, broken code that can't be cleanly fixed forward, lost tests) and you need a clean return to the previous known-good state. Invoke with "/rollback" or phrases like "roll back to v0.2.0", "undo this gate", "revert to the last gate". Do NOT use for small code changes (use git), for aborting in-progress work before gate close (just discard the branch), or for anything outside the Syntaris gate structure.
---

# ROLLBACK SKILL - Syntaris v0.5.2

## What rollback means in Syntaris

A Syntaris gate close commits a combined state change:

1. Code commits on the current branch
2. New entries in DECISIONS.md
3. New entries in MEMORY_EPISODIC.md
4. A REFLEXION entry in MEMORY_CORRECTIONS.md
5. A version bump in VERSION_ROADMAP.md
6. Possibly new entries in TESTS.md, PERFORMANCE.md, SECURITY.md,
   COMPONENT_REGISTRY.md

Naive `git reset --hard <prev>` only reverts (1). The memory files,
version roadmap, and other foundation artifacts drift out of sync with
the reverted code. This skill does the full reversion atomically.

## Prerequisites

Rollback only works if gate closes have been tagged. Syntaris's
gate-close protocol creates a git tag named `syntaris-gate-<version>`
and snapshots the foundation files to `.syntaris/snapshots/<version>/`
at each close. Projects that started under Blueprint v11.x will have
older `blueprint-gate-<version>` tags and `.blueprint/snapshots/`
directories; rollback supports both prefixes transparently so existing
projects continue to work after upgrading to Syntaris v0.5.2.

If the target gate was closed without these artifacts, rollback cannot
restore the memory files; in that case, offer to do a code-only git
reset and warn the user that memory files will be left in their current
drifted state.

## Protocol

**Step 1: confirm target gate.**
Ask the user "roll back to which version?" and list available tags from
both prefixes (newest first):
```bash
git tag --list 'syntaris-gate-*' 'blueprint-gate-*' --sort=-version:refname | head -10
```
If the user said "the last gate" interpret that as the most recent tag
under either prefix.

**Step 2: dry-run preview.**
Before touching anything, show the user exactly what will be changed:

- The git commits that will be discarded (output of `git log <target>..HEAD --oneline`)
- The foundation files that will be restored from snapshot. Look in
  `.syntaris/snapshots/<version>/` first; if not present, fall back to
  `.blueprint/snapshots/<version>/`.
- The version that VERSION_ROADMAP.md will revert to
- Any uncommitted local changes that will be lost

Say: "This will discard <N> commits and restore <M> foundation files to
the state at gate <version>. Proceed? (yes/no)"

Wait for explicit "yes". Any other response, abort.

**Step 3: atomic execution.**
Run the three reverts in order. If any fails, stop and report partial state.

1. **Stash any uncommitted changes** so they're recoverable:
   ```bash
   git stash push -u -m "pre-rollback-$(date +%s)"
   ```
2. **Reset code** to the target tag (use whichever prefix the tag has):
   ```bash
   git reset --hard <full-tag-name>   # e.g. syntaris-gate-v0.3.0 or blueprint-gate-v0.3.0
   ```
3. **Restore foundation files** from snapshot. Try the new path first,
   fall back to the old:
   ```bash
   if [ -d .syntaris/snapshots/<version> ]; then
       cp -r .syntaris/snapshots/<version>/* .
   else
       cp -r .blueprint/snapshots/<version>/* .
   fi
   ```

**Step 4: verify.**
Confirm VERSION_ROADMAP.md now shows the target version as current, and
that `git log -1 --format=%H` matches the tag's commit hash. Show the
user the output of `git status` so they can see a clean working tree.

**Step 5: record the rollback.**
Append an entry to MEMORY_EPISODIC.md:
```
ROLLBACK: <date> - reverted from v<broken> to v<target>. Reason: <user-provided>.
```
Then ask the user for the rollback reason in 1-2 sentences and append
a matching REFLEXION entry to MEMORY_CORRECTIONS.md. This is important:
rollbacks are expensive and the lesson from them should not be lost.

## Limitations you must surface to the user

- Rollback cannot recover commits pushed to a shared remote if others
  have pulled them. If the broken gate's commits were already pushed and
  pulled by teammates, do NOT run a non-interactive reset; instead
  offer a `git revert` path that produces new reverting commits.
- Rollback cannot recover files outside the repo or outside the
  snapshot tree (e.g., secrets in `.env`, database migrations applied
  to a live db, deployed infrastructure). The user is responsible for
  those domains.
- The stash created in step 3 is a safety net, not a commitment. It is
  not automatically restored. The user must decide whether to
  `git stash pop` it or discard it.

## Failure modes

If neither `.syntaris/snapshots/<version>/` nor `.blueprint/snapshots/<version>/`
exists: the gate was closed without the snapshot hook active. Offer
code-only reset with an explicit warning that memory files will not be
reverted, and recommend adding the gate-close snapshot step to future
gate closes.

If `git reset --hard` fails because the working tree has uncommitted
changes that the stash did not catch (untracked files in the ignore
list, etc.): abort, report the conflicting paths, and ask the user to
handle them before re-running rollback.

If the user attempts rollback across a destructive foundation change
(e.g., a CONTRACT.md rewrite that changed PROJECT_NAME): warn that the
snapshot may reference an earlier project identity and that restoring
it will overwrite the current CONTRACT.md entirely. Confirm again
before proceeding.
