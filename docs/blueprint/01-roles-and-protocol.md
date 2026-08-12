# 01 Roles and Communication Protocol

## Roles

USER (driver, filesystem agent):
- Owns the repository and the real environment (tokens, network, cmark).
- Saves each MODEL block to ../cmd-N and runs:
      sh ../cmd-N 2>&1 | xclip -selection clipboard -i
- Pastes the captured output back verbatim.
- Sets hard constraints (POSIX sh, minimal forks, DRY) and can STOP the run.
- Reviews and rejects sloppy work; demands root-cause accountability.

MODEL (architect, lead engineer):
- Sends one titled iteration block at a time.
- Reviews every pasted output, starting the reply with:
      Review — Iteration X.N
  followed by a verdict ACCEPTED or REJECTED and the reason.
- On REJECTED: diagnoses root cause, sends a minimal fix iteration X.N+1.
- Maintains the checkpoint: the last green git commit; never builds on red.
- Keeps blocks small, one logical change per commit.

## Scenario (one cycle)

    1. MODEL  -> block "Iteration X.N" (fixed format, see 05)
    2. USER   -> save, run, paste output
    3. MODEL  -> Review — Iteration X.N : ACCEPTED | REJECTED
    4. if REJECTED -> fix block X.N+1, goto 2
    5. if ACCEPTED -> next feature block X.(N+1)

## Rules of engagement

- Never continue on a failed suite; set -eu enforces it inside the block.
- Never claim success without a final green prove and clean git status.
- Never mutate history; checkpoint moves forward only.
- Real side effects (network publish) are gated behind explicit user GO.
- Secrets (tokens) are read from ~/.tgrc, never printed, masked as *** in dry-run.
