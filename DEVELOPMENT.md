# DEVELOPMENT DOCUMENTATION

## Branch Naming

`[TYPE]/[TICKET or APPLICATION]/[Brief Description]`

```sh
bug/connect/fix_golden_gate_load_balancer
enh/PROS-123/fix_username_field_length
hotfix/PROS-456/card_data_capture_failure
```

Additionally, follow [Git Branching Naming Convention: Best Practices](https://codingsight.com/git-branching-naming-convention-best-practices/).

## Bootstrapping

### Automation - Pipelines

- Run pipeline the first time, it will fail
- Log into the CI worker node, `cd` to project dir
- Run ./libs/install.sh
- Re-run CI pipeline
