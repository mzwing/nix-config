{pkgs, ...}: {
  languages.swift = {
    enable = true;
    lsp.enable = true;
  };

  packages = with pkgs; [
    cocoapods
    create-dmg
    ios-deploy
    swift-format
    swiftlint
    xcbeautify
    xcodegen
    macdylibbundler
  ];

  enterTest = ''
    command -v swift
    command -v sourcekit-lsp
    command -v pod
    command -v create-dmg
    command -v ios-deploy
    command -v swift-format
    command -v swiftlint
    command -v xcbeautify
    command -v xcodegen
    command -v macdylibbundler
  '';
}
