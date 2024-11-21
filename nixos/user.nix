{ config, pkgs, ... }:

{
  networking.extraHosts = ''
    172.18.0.6 tuleap-web.tuleap-aio-dev.docker
  '';

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    groups = {
      vinc = { gid = 1000; };
    };
    users.vinc = {
      isNormalUser = true;
      description = "Vincent";
      group = "vinc";
      extraGroups = [ "networkmanager" "wheel" "docker" ];
      shell = pkgs.zsh;
      packages = with pkgs; [
        vlc
        yubikey-manager-qt
        (vscode-with-extensions.override {
          vscode = vscodium;
          vscodeExtensions = with vscode-extensions; [
            bbenoist.nix
            jnoortheen.nix-ide
            ms-python.python
            hookyqr.beautify
            waderyan.gitblame
            hashicorp.terraform
            redhat.vscode-yaml
            bierner.emojisense
            redhat.ansible
            mhutchie.git-graph
          ];
          # ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          #   {
          #     name = "Ansible";
          #     publisher = "redhat";
          #     version = "24.8.3";
          #     sha256 = "8DlOB3bog/VeW5YAU2DQhlkvCf+3JqVJNbPJJJWYjI4=";
          #   }
          # ];
        })
      ];
    };
  };
}
