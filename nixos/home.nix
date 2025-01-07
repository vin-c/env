{ config, lib, pkgs, unfreePkgs, ... }:
let
  onePassPath = "~/.1password/agent.sock";
in {
  home.packages = with pkgs; [
    chromium
    curl
    dig
    firefox
    git
    tcpdump
    wget
    whois

    d2
    docker
    ffmpeg
    glibc
    htop
    kdePackages.isoimagewriter
    libvirt
    nmon
    openssl
    php82
    qemu_kvm

    _1password-cli
    _1password-gui
    adi1090x-plymouth-themes
    libreoffice-fresh
    neovim
    oh-my-zsh
    plymouth
    powerline-fonts
    rdap
    ripgrep
    terminator
    tmux
    uutils-coreutils-noprefix
    virt-manager
    vlc
    yubikey-manager
    zip
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions = with vscode-extensions; [
        bbenoist.nix
        bierner.emojisense
        hashicorp.terraform
        hookyqr.beautify
        jnoortheen.nix-ide
        mhutchie.git-graph
        ms-python.python
        redhat.ansible
        redhat.vscode-yaml
        RoweWilsonFrederiskHolme.wikitext
        waderyan.gitblame
      ];
    })
    unfreePkgs.terraform
    # unfreePkgs.vscodium-fhs
    unfreePkgs.vault-bin
  ];

  home.sessionVariables = {
    EDITOR = "vim";
  };

  programs = {
    home-manager.enable = true;

    direnv = {
      enable = true;
      # loadInNixShell = true;
      nix-direnv.enable = true;
    };

    # _1password-cli.enable = true;
    # _1password-gui = {
    #   enable = true;
    #   # Certain features, including CLI integration and system authentication support,
    #   # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    #   polkitPolicyOwners = [ "vinc" ];
    # };

    gpg = {
      enable = true;
      settings = {
        no-emit-version = true;
        no-comments = true;
        keyid-format = "0xlong";
        with-fingerprint = true;
        list-options = "show-uid-validity";
        verify-options = "show-uid-validity";
        keyserver-options = "include-revoked";
        personal-cipher-preferences = "AES256 AES192 AES CAST5";
        personal-digest-preferences = "SHA512 SHA384 SHA256 SHA224";
        cert-digest-algo = "SHA512";
        default-preference-list = "SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed";
      };
    };

    ssh = {
      enable = true;
      extraConfig = ''
        Host my.enalean.com tuleap.net
          User gitolite
          IdentityFile ~/.ssh/id_vgj-scm.pub

        Host github.com
          User git
          IdentityFile ~/.ssh/id_vgj-scmbis

        Host valid-vinc
          HostName tuleap.valid.enalean.com
          User gitolite
          IdentityFile ~/.ssh/id_vgj-scm.pub

        Host valid-vincbis
          HostName tuleap.valid.enalean.com
          User gitolite
          IdentityFile ~/.ssh/id_vgj-scmbis

        Host *
          User vinc
          IdentityAgent ${onePassPath}
          IdentitiesOnly yes
      '';
    };

    git = {
      enable = true;
      extraConfig = {
        gpg = {
          format = "ssh";
        };
        "gpg \"ssh\"" = {
          program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
        };
        commit = {
          gpgsign = true;
        };
        user = {
          signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMd8l3hTcfZ2PJ//kO7auYjaFIBhKWLzORkbJvzr3PKJ";
          name = "Vincent Gatignol";
	        email = "vincent.gatignol-jamon@enalean.com";
        };
      };
    };

    bash = {
      enable = true;
      initExtra = ''

      '';
    };
  };

  home.stateVersion = "24.11";
}
