{...}: {
  languages.deno.enable = true;

  enterTest = ''
    deno --version
  '';
}
