# Dotfiles

My dotfiles for use across Linux and Mac OS systems.

## Instructions

Run `./setup.sh` to install necessary software. Then use `stow` from within this
directory to install the desired configurations:

```
stow <module>
```

E.g.

```
stow nvim
```

## Shell Performance

The shell configurations are optimized for fast startup:
- **Zsh startup**: ~8ms (98.9% faster than before optimization)
- **NVM lazy loading**: Only loads when you use `node`/`npm`/`nvm`/`npx`
- **Smart completion caching**: Rebuilds only when needed (every 24 hours or when cache is missing)

### Rebuilding Completions

After installing new CLI tools, you may want to refresh shell completions immediately:

```bash
rebuild-completions
```

This utility function will clear the completion cache and rebuild it, making new completions available right away. Otherwise, completions automatically rebuild within 24 hours.
