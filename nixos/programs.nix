{ config, pkgs, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  #   "displaylink"
  # ];

  # Allow nix flakes
  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.auto-optimise-store = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable virtualisation
  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  ];

  programs = {
    chromium.enable = true;

    # plasma = {
    #   enable = true;

    #   #
    #   # Some high-level settings:
    #   #
    #   workspace = {
    #     clickItemTo = "select";
    #     lookAndFeel = "org.kde.breezedark.desktop";
    #     cursor.theme = "Bibata-Modern-Ice";
    #     iconTheme = "Papirus-Dark";
    #     wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Next/contents/images_dark/3840x2160.png";
    #   };

    #   hotkeys.commands."launch-konsole" = {
    #     name = "Launch Konsole";
    #     key = "Meta+X";
    #     command = "konsole";
    #   };

    #   panels = [
    #     # Windows-like panel at the bottom
    #     {
    #       location = "bottom";
    #       widgets = [
    #         "org.kde.plasma.kickoff"
    #         "org.kde.plasma.icontasks"
    #         "org.kde.plasma.marginsseparator"
    #         "org.kde.plasma.systemtray"
    #         "org.kde.plasma.digitalclock"
    #       ];
    #     }
    #     # Global menu at the top
    #     {
    #       location = "top";
    #       height = 26;
    #       widgets = [ "org.kde.plasma.appmenu" ];
    #     }
    #   ];

    #   #
    #   # Some mid-level settings:
    #   #
    #   shortcuts = {
    #     ksmserver = {
    #       "Lock Session" = [
    #         "Screensaver"
    #         "Meta+L"
    #       ];
    #     };

    #     kwin = {
    #       "Expose" = "Meta+,";
    #     };
    #   };
    # };

    vim.defaultEditor = true;

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = false;
      ohMyZsh = {
        enable = true;
        theme = "agnoster";
        plugins = [ "sudo" "git" ];
      };
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable tailscale
  services = {
    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };
    yubikey-agent = {
      enable = true;
    };
  };

}
