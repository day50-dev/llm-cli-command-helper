zummoner() {
  local QUESTION="$BUFFER"
  local PROMPT="
  You are an experienced Linux engineer with expertise in all Linux
  commands and their functionality across different Linux systems.

  Given a task, generate a single command or a pipeline
  of commands that accomplish the task efficiently.
  This command is to be executed in the current shell, zsh.
  For complex tasks or those requiring multiple
  steps, provide a pipeline of commands.
  Ensure all commands are safe and prefer modern ways. For instance,
  homectl instead of adduser, ip instead of ifconfig, systemctl, journalctl, etc.
  Make sure that the command flags used are supported by the binaries
  usually available in the current system or shell.
  If a command is not compatible with the
  system or shell, provide a suitable alternative.

  The system information is: $(uname -a) (generated using: uname -a).
  The user is $USER. Use sudo when necessary

  Create a command to accomplish the following task: $QUESTION

  If there is text enclosed in paranthesis, that's what ought to be changed.
  If there's a comment (#), then the stuff after is is the instructions, you should put the stuff there.

  Output only the command as a single line of plain text, with no
  quotes, formatting, or additional commentary. Do not use markdown or any
  other formatting. Do not include the command into a code block.
  Don't include the shell itself (bash, zsh, etc.) in the command.
  "
  if which llcat >& /dev/null; then
    _ll="llcat -nt -u $LLC_SERVER -bq think"
    [[ -n "$LLC_KEY_FILE" ]] && _ll+=" -k $(cat $LLC_KEY_FILE)"
    [[ -n "$LLC_MCP" ]]      && _ll+=" -mf $LLC_MCP"
    model="$LLC_MODEL"
  else
    _ll="llm"

    if [[ -r "$HOME/$config/io.datasette.llm/default_model.txt" ]]; then
      model=$(cat "$HOME/$config/io.datasette.llm/default_model.txt")
    else
      model=$(llm models default)
    fi
  fi

  BUFFER="$QUESTION ... $model"
  zle -R
  local response=$($=_ll -m $model "$PROMPT")
  local COMMAND=$(echo "$response" | sed 's/```//g' | tr -d '\n')
  #echo "$(date %s) {$QUESTION | $response}" >> /tmp/zummoner
  if [[ -n "$COMMAND" ]] ; then
    if [[ -n "$ZUMMONER_SPELL" ]]; then 
      [[ "$QUESTION" = *"#"* ]] && QUESTION="${QUESTION#*\# }"
      BUFFER="${COMMAND%%\#*} # $QUESTION"
    else
      BUFFER="$COMMAND"
    fi
    CURSOR=${#BUFFER}
  else
    BUFFER="$QUESTION ... no results"
  fi
}

NN=0
zle -N zummoner

# This is the comment appending option, it will only work if
# this shell feature is on
if [[ -n "$ZUMMONER_SPELL" ]]; then
    setopt interactive_comments
fi

if ! bindkey | grep -q "\^Xx"; then
  bindkey '^Xx' zummoner
elif ! bindkey | grep -q zummoner; then
  echo "I'm not going to unbind ^Xx, you'll need to do this yourself"
fi
