{
  description = "LinkNexus nix-darwin system flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    eza = {
      url = "github:eza-community/eza";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
      };
    };
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    eza,
    rust-overlay,
    flake-utils,
  }: let
    # Packages shared across both platforms
    sharedPackages = pkgs: [
      pkgs.neovim
      pkgs.tmux
      pkgs.fzf
      pkgs.zoxide
      pkgs.starship
      pkgs.stow
      pkgs.eza
      pkgs.tree-sitter
      pkgs.dotnet-sdk_10
      pkgs.rustc
      pkgs.cargo
      pkgs.uv
      pkgs.python314
      pkgs.lazygit
      pkgs.ripgrep
      pkgs.avrdude
      pkgs.pkgsCross.avr.buildPackages.gcc
      pkgs.pkgsCross.avr.buildPackages.binutils
      pkgs.pkgsCross.avr.avrlibc
      pkgs.cmake
      pkgs.gnumake
      pkgs.bear
      pkgs.simavr
      pkgs.nodejs
      pkgs.bun
      pkgs.tsx
      pkgs.opencode
      pkgs.powershell
      pkgs.yazi
      pkgs.sqlit-tui
      pkgs.ascii-image-converter
      pkgs.gh
      pkgs.viu
      pkgs.platformio
      pkgs.mailpit
      pkgs.codex
      pkgs.claude-code
    ];

    # Darwin-specific config
    darwinConfiguration = {pkgs, ...}: {
      environment.systemPackages = sharedPackages pkgs;

      nix.settings.experimental-features = "nix-command flakes";
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 6;
      nixpkgs.hostPlatform = "aarch64-darwin";
      nixpkgs.config.allowUnfree = true;
      nix.gc = {
        automatic = true;
        interval = {
          Weekday = 0;
          Hour = 0;
          Minute = 0;
        };
        options = "--delete-older-than 7d";
      };
      nix.settings.auto-optimise-store = true;
      security.pam.services.sudo_local = {
        touchIdAuth = true;
        reattach = true;
      };
      fonts.packages = [
        pkgs.nerd-fonts.monaspace
        pkgs.inter
        pkgs.nerd-fonts.fira-code
        pkgs.nerd-fonts.commit-mono
        pkgs.nerd-fonts.caskaydia-cove
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.nerd-fonts.blex-mono
      ];
      system.primaryUser = "levynkeneng";
      system.defaults = {
        dock.autohide = true;
        dock.persistent-apps = [
          "/Applications/kitty.app"
          "/Applications/Thunderbird.app"
          "/Applications/Zen.app"
          "/Applications/Moonlight.app"
        ];
      };
    };

    # Linux config
    linuxConfiguration = {pkgs, ...}: {
      environment.systemPackages = sharedPackages pkgs;

      nix.settings.experimental-features = "nix-command flakes";
      nixpkgs.config.allowUnfree = true;
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
      nix.settings.auto-optimise-store = true;
    };
  in {
    darwinConfigurations."main" = nix-darwin.lib.darwinSystem {
      modules = [darwinConfiguration];
    };

    # Apply on Fedora with:
    # $ nix-env -iA nixpkgs.nix && nix profile install .#linuxPackages
    packages.x86_64-linux.default = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in
      pkgs.buildEnv {
        name = "linux-packages";
        paths = sharedPackages pkgs;
      };
  };
}
