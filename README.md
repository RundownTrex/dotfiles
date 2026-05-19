# Dotfiles (GNU Stow Experiment)

This branch is an experimental migration of my dotfiles repository to use GNU Stow.

The main branch remains the source of truth and uses the existing manual workflow.

## Status

- Repository restructured for Stow
- Scripts excluded from Stow management
- No live migration performed on the main machine
- Branch may be abandoned or replaced later

## Layout

Each package mirrors the final location inside `$HOME`.

Example:

```text
fish/
└── .config/
    └── fish/

hypr/
└── .config/
    └── hypr/

bash/
└── .bashrc

picom/
└── .config/
    └── picom.conf

mime/
└── .config/
    └── mimeapps.list
