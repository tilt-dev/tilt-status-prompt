# Usage

Put tilt-status-prompt.sh somewhere on your machine, e.g.:
```
mkdir -p ~/bin
curl github.com/tilt-dev/tilt-status-prompt/tilt-status-prompt.sh > ~/bin/tilt-status-prompt.sh
```

`source` it in your ~/.bashrc, e.g.:
```
echo 'source ~/bin/tilt-status-prompt.sh' > ~/.bashrc
```

change .bashrc to use `tilt_ps1` in your `$PS1`, e.g.:
```
export PS1='[\t $(__tilt_ps1)\$ '
```
