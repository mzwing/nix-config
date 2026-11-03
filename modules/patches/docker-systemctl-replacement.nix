{
  # systemctl3 refuses hyphenated keys like X-StopIfChanged and the bare command names systemd's own units use, which NixOS's systemd finds in its bin. Drop once upstream accepts both
  mzwing.patches.docker-systemctl-replacement = final: prev: {
    nur =
      prev.lib.updateManyAttrsByPath [
        {
          path = ["repos" "mzwing" "docker-systemctl-replacement"];
          update = systemctl3:
            systemctl3.overrideAttrs {
              postPatch = ''
                substituteInPlace files/docker/systemctl3.py \
                  --replace-fail 're.match(r"(\w+) *=(.*)", line)' 're.match(r"([\w-]+) *=(.*)", line)' \
                  --replace-fail 'prefix, newcmd = checkprefix(cmd)' 'prefix, newcmd = checkprefix(cmd); newcmd = "${final.systemd}/bin/" + newcmd if newcmd[:1].isalnum() else newcmd'
              '';
            };
        }
      ]
      prev.nur;
  };
}
