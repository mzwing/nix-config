{pkgs, ...}: {
  languages.java = {
    enable = true;
    jdk.package = pkgs.openjdk17;
    gradle.enable = true;
    maven.enable = true;
    lsp.enable = true;
  };

  enterTest = ''
    java -version
    gradle --version
    mvn --version
    command -v jdtls
  '';
}
