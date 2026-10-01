{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  zstd,
  versionCheckHook,
  libGL,
  libxcb,
  libxkbcommon,
  vulkan-loader,
  wayland,
}:

let
  # Version info (auto-updated by GitHub Actions after minisign verification)
  sources = lib.importJSON ./sources.json;
  inherit (sources) version;
in
stdenv.mkDerivation {
  pname = "openlogi";
  inherit version;

  # Prebuilt Arch Linux package from the upstream GitHub Release. Its contents
  # mirror the upstream Nix build (packaging/linux/package.nix): the same four
  # binaries, desktop entry, icons, udev rule and systemd user unit.
  src = fetchurl {
    url = "https://github.com/AprilNEA/OpenLogi/releases/download/v${version}/openlogi-v${version}-linux-amd64.pkg.tar.zst";
    inherit (sources) hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    zstd
  ];

  # DT_NEEDED of openlogi-desktop / openlogi-overlay (the rest only need libc
  # and libgcc_s, which autoPatchelfHook finds through stdenv)
  buildInputs = [
    libxcb
    libxkbcommon
    (lib.getLib stdenv.cc.cc)
  ];

  # GPUI dlopens these at runtime, so they never appear in DT_NEEDED. Same set
  # as upstream's runtimeLibs, but added to every binary: upstream only patches
  # openlogi-desktop, which leaves openlogi-overlay panicking with NoWaylandLib.
  runtimeDependencies = [
    libGL
    vulkan-loader
    wayland
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 -t "$out/bin" usr/bin/*
    cp -r usr/share "$out/share"
    install -Dm644 etc/udev/rules.d/70-openlogi.rules \
      "$out/lib/udev/rules.d/70-openlogi.rules"
    install -Dm644 usr/lib/systemd/user/openlogi-agent.service \
      "$out/share/systemd/user/openlogi-agent.service"

    substituteInPlace "$out/share/systemd/user/openlogi-agent.service" \
      --replace-fail \
        "ExecStart=/usr/bin/openlogi-agent" \
        "ExecStart=$out/bin/openlogi-agent"

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  preInstallCheck = ''
    for binary in openlogi openlogi-agent openlogi-desktop openlogi-overlay; do
      test -x "$out/bin/$binary"
    done
  '';

  meta = {
    description = "Local-first companion for Logitech HID++ peripherals (prebuilt release)";
    homepage = "https://github.com/AprilNEA/OpenLogi";
    license = with lib.licenses; [
      mit
      asl20
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "openlogi";
    platforms = [ "x86_64-linux" ];
  };
}
