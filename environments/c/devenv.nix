{pkgs, ...}: {
  languages.c.enable = true;

  env.CMAKE_GENERATOR = "Ninja";

  packages = with pkgs; [
    ccache
    clang-tools
    cmake
    cmake-format
    cmake-lint
    ninja
    vcpkg
    gcc
    clang
  ];

  enterTest = ''
    ccache --version
    clang --version
    clang-tidy --version
    cmake --version
    cmake-format --version
    cmakelint --version
    ninja --version
    vcpkg version
    gcc --version
  '';
}
