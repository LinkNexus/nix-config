{
  description = "LinkNexus nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    eza = {
      url = "github:eza-community/eza";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
      };
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    nix-homebrew,
    eza,
    rust-overlay,
    flake-utils,
  }: let
    configuration = {pkgs, ...}: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [
        pkgs.neovim
        pkgs.tmux
        pkgs.ghostty-bin
        pkgs.fzf
        pkgs.zoxide
        pkgs.starship
        pkgs.stow
        pkgs.eza
        pkgs.tree-sitter
        pkgs.nodejs_25
        pkgs.dotnet-sdk_10
        pkgs.cargo
        pkgs.uv
        pkgs.python315
        pkgs.lazygit
        pkgs.ripgrep

        pkgs.avrdude # flashing tool
        pkgs.pkgsCross.avr.buildPackages.gcc # avr-gcc cross-compiler
        pkgs.pkgsCross.avr.buildPackages.binutils # avr-objcopy, avr-size etc.
        pkgs.pkgsCross.avr.avrlibc
        pkgs.cmake
        pkgs.gnumake
        pkgs.bear
        pkgs.simavr

        pkgs.bun
      ];

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      fonts.packages = [
        pkgs.nerd-fonts.monaspace
      ];

      homebrew = {
        enable = true;
        casks = [
          "raycast"
          "zen"
          "thunderbird"
          "visual-studio-code@insiders"
        ];
        onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      system.primaryUser = "levynkeneng";

      system.defaults = {
        # NSGlobalDomain._HIHideMenuBar = true;
        dock.autohide = true;
        dock.persistent-apps = [
          "${pkgs.ghostty-bin}/Applications/Ghostty.app"
          "/Applications/Thunderbird.app"
          "/Applications/Zen.app"
        ];
      };
    };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."main" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "levynkeneng";
          };
        }
      ];
    };
  };
}
