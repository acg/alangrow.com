
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "SSH Pubkey Setup In One Command",
        "date": "2005-02-14T00:00:00-0000",
        "root": ".."
      }
    }

Transfer your ssh public key to a remote host, for passwordless logins, in one command:

```bash
ssh < "$key" "$@" '
  cat > $HOME/authorized_keys && 
  mkdir -p .ssh &&
  cat $HOME/authorized_keys >> $HOME/.ssh/authorized_keys &&
  rm -f $HOME/authorized_keys &&
  chmod 0700 .ssh &&
  chmod 0600 $HOME/.ssh/authorized_keys'
```

Note that newer versions of ssh now have `ssh-copy-id(1)`.

