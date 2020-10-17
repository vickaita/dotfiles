{ config, pkgs, ... }:

{
  home = {
    username = "vickaita";
    homeDirectory = "/home/vickaita";

    stateVersion = "20.09";

    packages = with pkgs; [
      curl
      fd
      fzf
      git
      jq
      nodejs
      ripgrep
      stow
      tree
      wget
    ];
  };

  programs = {
    fish = {
      enable = true;
    };

    fzf = {
      enable = true;
    };

    git = {
      enable = true;
      delta.enable = true;
      userName = "Vick Aita";
      userEmail = "vickaita@gmail.com";
      extraConfig = {
        core = {
          editor = "${pkgs.neovim}";
        };
      };
    };

    home-manager = {
      enable = true;
    };

    neovim = {
      enable = true;
    };

    zsh = {
      enable = true;
    };
  };
}
