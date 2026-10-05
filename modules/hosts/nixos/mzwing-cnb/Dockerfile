FROM nixos/nix:latest AS build

COPY . /src
RUN nix --extra-experimental-features 'nix-command flakes' build --accept-flake-config --out-link /system /src#nixosConfigurations.mzwing-cnb.config.system.build.toplevel \
  && nix --extra-experimental-features nix-command copy --no-check-sigs --to /out /system \
  && nix-env --store /out --profile /out/nix/var/nix/profiles/system --set "$(readlink /system)" \
  && mkdir -p /out/run /out/var/empty \
  && mkdir -m 1777 /out/tmp

FROM scratch

COPY --from=build /out /
ENV PATH=/etc/profiles/per-user/root/bin:/nix/var/nix/profiles/system/sw/bin
# agenix decrypts into it and WakaTime's vault command reads from it, so both sides must see the same value.
ENV XDG_RUNTIME_DIR=/run/user/0
RUN ["/nix/var/nix/profiles/system/activate"]
