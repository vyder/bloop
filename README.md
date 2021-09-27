# bloop

## Install

```
❯ ./install
```

## Usage

```
❯ bloop --help

bloop
-----
Blueprint CLI

Usage:
   ❯ bloop --register PATH TEMPL_NAME -t [TYPE]
   => Registers a new template entry with TEMPL_NAME in the blueprint store
      allowing it to be copied.
   => The type determines what files/folders to ignore while copying
      TYPE:
         - defaults to 'node'
         - other values: (none yet, TODO)

   ❯ bloop TEMPL_NAME [PATH]
   => Clones the specified template to the current path with the same
      name as template - if a PATH is not provided

   ❯ bloop --help
   => Displays this help text
```

## Uninstall

```
❯ ./install --remove
```