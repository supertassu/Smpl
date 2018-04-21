# Smpl 

![Screeshot](https://i.imgur.com/TYzXJ8V.jpg)<br/>
Smpl is a (very wip) zsh prompt focusing on simplicity and elegancy.

```shell
# .zshrc
antibody bundle supertassu/Smpl
```

## Configuration

### `PROMPT_SMPL_HIDE_TIME`
If set, time will not be shown in the prompt.

### `PROMPT_SMPL_HIDE_CWD`
If set, working directory will not be shown in the prompt.

### `PROMPT_SMTL_HIDE_GIT_BRANCH`
If set, git branch will not be shown in the prompt.

### `PROMPT_SMTL_DISABLE_DIRTY_CHECK`
If set, the git dirty check will be disabled. Will be ignored if `PROMPT_SMTP_HIDE_GIT_BRANCH` is set.

### `PROMPT_SMPL_HIDE_NVM`
If set, current node version (via NVM) will not be shown.

### `PROMPT_SMPL_HIDE_EXEX_TIME`
If set, executation time will not be shown in the prompt.

### `PROMPT_SMPL_SHOW_LOW_TIMES`
If set, executation times lower than `$PROMPT_SMPL_EXEC_TIME_TRESHOLD ms` will be shown.

### `PROMPT_SMPL_EXEC_TIME_TRESHOLD`
Defines minimum execution time (in milliseconds) to be displayed on the prompt. Will be ignored if `PROMPT_SMPL_SHOW_LOW_TIMES` is set.
