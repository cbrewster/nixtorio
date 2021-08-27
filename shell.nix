{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.morph

    # keep this line if you use bash
    pkgs.bashInteractive
  ];
}
