# General Workflow regarding branches/image streams

## I want to submit a fix/feature, what do I do?

PR against main branch, do not PR anything against the stable branch. If it's an important improvement and has to be shipped immediately then apply the "cherry-pick" label to your PR. State why your change is important and needs to be cherry-picked.

The Aurora-Backport bot will open a PR for the stable-f$FEDORA_VERSION branch after the PR has been successfully merged into main.

### Manual Cherry-pick

If the bot is broken ([this action powers it](https://github.com/korthout/backport-action)) for whatever reason then this can still be done manually via the following:

```
<use things like git log to find the relevant commit>
git switch stable-f44
git switch -c backport-important-fix-xyz
git cherry-pick -x deadbeef
```

Make sure that the commit is actually a commit from the main branch, do not use the commits that belong to PR branches. So you can still trace the origin of the original commit back.

### Only :stable/:latest is broken but :testing is not

The fix should still go in the main branch. Rare exceptions can be made when a feature is removed in the main branch and it's only available in the stable branch and it's causing failures in CI.

## Merge changes from main into stable

The [pull bot](https://github.com/wei/pull) will open a PR that wants to merge changes from main into stable. Every time there is a new commit in main the PR will run CI again. These PRs can be merged any time as long as there are no known issues on `:testing`.

## Branching future Fedora versions (Fedora Betas)

- (wait for Fedora Beta announcement)
- PR ublue-os/akmods
- bump testing version in Justfile
- deal with the wrath of 3rd party repos and the like

## new :stable/:latest based on new fedora version

- wait for the proper Fedora Release (package update freeze is over)
- wait for coreos:stable release (~2 weeks after Fedora) -> PR ublue-os/akmods
- bump workflows and justfile from i.e. stable-f44 to stable-f45 in main branch

After that you make a new branch called stable-f45 and update branch protection rules for the new branch.

## Overview

|                                                           | :stable                                                                                                         |  :latest                                                                                           | :testing                                                        |
|-----------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|-----------------------------------------------------------------|
| builds from which branch  ?                               | stable-f$FEDORA_VERSION                                                                                         |  stable-f$FEDORA_VERSION                                                                           | main                                                            |
| kernel flavor                                             | coreos-stable pinned when regressions occur                                                                     |  whatever fedora ships, pinned when really bad regressions occur                                   | whatever fedora ships, pinned when really bad regressions occur |
| Published when?                                           | weekly cron, manual trigger in case of emergency                                                                |  when PRs are merged, daily or multiple times a day                                                | when PRs are merged, daily or multiple times a day              |
| Built when?                                               | Ideally only on promotion PRs, but on all PRs would be fine as well to see if they still build                  |  on merges into stable-f$FEDORA_VERSION                                                            | on merges into main                                             | 
| Why does this exist                                       | to protect users from fedora regressions so there is enough time in between to fix/workaround  things if needed |  having the newest kernel from fedora is useful to spot regressions before they make it to :stable | Test changes we make in ublue so they can go to the main branch |
| Who should use this?                                      | Regular users                                                                                                   |  Enthusiasts                                                                                       | Enthusiasts, Testers, People with multiple Aurora machines      |

