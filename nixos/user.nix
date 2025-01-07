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
    };
  };
}
