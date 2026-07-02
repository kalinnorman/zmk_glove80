{ pkgs ? (import ./nix/pinned-nixpkgs.nix {}) }:
let
  inherit (pkgs) newScope;
  inherit (pkgs.lib) makeScope;
in

makeScope newScope (self: with self; {
  west = pkgs.python3Packages.west.overrideAttrs(attrs: {
    patches = (attrs.patches or []) ++ [./nix/west-manifest.patch];
  });

  # To update the pinned Zephyr dependecies using west and update-manifest:
  #  nix shell -f . west -c west init -l app
  #  nix shell -f . west -c west update
  #  nix shell -f . update-manifest -c update-manifest > nix/manifest.json
  # Note that any `group-filter` groups in west.yml need to be temporarily
  # removed, as `west update-manifest` requires all dependencies to be fetched.
  update-manifest = callPackage ./nix/update-manifest { inherit west; };

  combine_uf2 = a: b:
    let combine = name: pkgs.runCommandNoCC "combined_${a.name}_${b.name}" {}
    ''
      mkdir -p $out
      cat ${a}/zmk.uf2 ${b}/zmk.uf2 > $out/${name}.uf2
    '';
  in (combine "glove80") // { __functor = self: name: combine name; };

  zephyr = callPackage ./nix/zephyr.nix { };

  zmk = callPackage ./nix/zmk.nix { };

  glove80_left = zmk.override {
    board = "glove80_lh";
  };

  glove80_right = zmk.override {
    board = "glove80_rh";
  };

  glove80_combined = combine_uf2 glove80_left glove80_right "glove80";

  go60_left = zmk.override {
    board = "go60_lh";
  };

  go60_right = zmk.override {
    board = "go60_rh";
  };

  go60_combined = combine_uf2 go60_left go60_right "go60";

  glove80_v0_left = zmk.override {
    board = "glove80_v0_lh";
  };

  glove80_v0_right = zmk.override {
    board = "glove80_v0_rh";
  };

  # Seeed XIAO BLE as a BLE central "dongle", with the Glove80 halves
  # demoted to peripherals. Build and flash all three of:
  #   - glove80_dongle       (flash to the XIAO)
  #   - glove80_dongle_left  (flash to the LH half instead of glove80_left)
  #   - glove80_right        (unchanged - RH is already a peripheral)
  # Flash the matching glove80_settings_reset_* firmware to all three first
  # if they were previously paired in another role.
  glove80_dongle_xiao = zmk.override {
    board = "seeeduino_xiao_ble";
    shield = "glove80_dongle";
  };

  glove80_dongle_left = zmk.override {
    board = "glove80_lh";
    kconfig = ./app/boards/arm/glove80/glove80_lh_dongle_peripheral.conf;
  };

  glove80_dongle_right = zmk.override {
    board = "glove80_rh";
  };

  glove80_settings_reset_dongle = zmk.override {
    board = "seeeduino_xiao_ble";
    shield = "settings_reset";
  };

  glove80_settings_reset_left = zmk.override {
    board = "glove80_lh";
    shield = "settings_reset";
  };

  glove80_settings_reset_right = zmk.override {
    board = "glove80_rh";
    shield = "settings_reset";
  };
})
