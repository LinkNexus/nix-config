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
      pkgs.wget
      pkgs.neovim
      pkgs.tmux
      pkgs.fzf
      pkgs.bat
      pkgs.zoxide
      pkgs.starship
      pkgs.zsh-autosuggestions
      pkgs.eza
      pkgs.tree-sitter
      pkgs.dotnet-sdk_10
      pkgs.rustc
      pkgs.cargo
      pkgs.uv
      pkgs.python314
      pkgs.lazygit
      pkgs.ripgrep
      pkgs.cmake
      pkgs.gnumake
      pkgs.bear
      pkgs.nodejs
      pkgs.bun
      pkgs.tsx
      pkgs.powershell
      pkgs.yazi
      pkgs.sqlit-tui
      pkgs.gh
      pkgs.mailpit
      pkgs.ninja
      pkgs.pkgsCross.mingwW64.buildPackages.gcc
      pkgs.btop
      pkgs.usbutils
      pkgs.claude-code
      pkgs.ffmpeg
    ];

    # Darwin-specific config
    darwinConfiguration = {pkgs, ...}: {
      environment.systemPackages =
        sharedPackages pkgs
        ++ [
          pkgs.lua5_5
        ];

      # direnv + nix-direnv, so a project's toolchain can live in its own
      # flake devShell and be entered automatically on `cd` rather than
      # having to be installed globally. Without the automatic entering,
      # per-project shells are friction nobody sustains -- which is why
      # this lands before any devShell does.
      #
      # nix-direnv.enable and enableZshIntegration both default to true,
      # hence the single line. The zsh hook deliberately does NOT live in
      # zsh/rc.d/ with the rest of the shell config: /etc/zshrc is already
      # nix-darwin-generated and is sourced before $ZDOTDIR/.zshrc, so the
      # module's own integration is both earlier and declarative. Don't
      # add a second `direnv hook zsh` in rc.d -- it would hook twice.
      #
      # NOTE: this is darwin-only. linuxConfiguration below is consumed as
      # a plain buildEnv via `nix profile install`, where programs.* module
      # options don't apply at all, so the Fedora path still has neither
      # direnv nor a hook. Deliberately not plumbed until that path is
      # actually used for development.
      programs.direnv.enable = true;

      # Link the dotnet SDK's own tree into the system profile, so
      # /run/current-system/sw/share/dotnet exists as a stable path.
      #
      # DOTNET_ROOT has to point at the SDK's share/dotnet directory, and
      # zsh/rc.d/70-env.zsh used to derive it by resolving `which dotnet`
      # all the way down to its /nix/store path. That is correct at the
      # moment a shell starts and wrong from the next rebuild onwards:
      # every already-open shell -- and everything launched from one,
      # Neovim's dotnet plugins included -- keeps pointing at the previous
      # dotnet-sdk generation. Because that store path is still present,
      # dotnet silently pairs the new SDK with the old host and runtime
      # ("the installed dotnet and the runtime have conflicting versions")
      # rather than failing outright. Worse, nix.gc below runs weekly with
      # --delete-older-than 7d, so eventually the stale path vanishes and
      # those shells break hard instead.
      #
      # Going through /run/current-system fixes it for good: that symlink
      # is repointed on every activation, so the same literal string
      # resolves to whichever SDK the current generation ships, and a
      # stale environment is no longer stale in any way that matters.
      # nix-darwin's default pathsToLink is deliberately minimal (only
      # /share/info, /share/man and friends), hence the explicit entry.
      environment.pathsToLink = ["/share/dotnet"];

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
