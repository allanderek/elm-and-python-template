{ pkgs, lib, config, inputs, ... }:

{
  dotenv.enable = true;
  dotenv.disableHint = false;


  # https://devenv.sh/packages/
  packages = [ 
    pkgs.git 
    pkgs.gnumake
    pkgs.fd
    pkgs.sd
    pkgs.nodePackages.sass
    pkgs.vscode-langservers-extracted
    pkgs.watchexec
    pkgs.lightningcss
    pkgs.sqlite
    pkgs.litecli
    # Required for copilot
    pkgs.nodejs
    pkgs.elmPackages.elm-review
    pkgs.elmPackages.elm-json
    # Currently broken :(
    # pkgs.comby
    ];

  # https://devenv.sh/languages/
  languages.elm.enable = true;
  languages.python.enable = true;

}
