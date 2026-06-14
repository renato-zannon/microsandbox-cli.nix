{ libkrunfw, fetchFromGitHub, fetchurl }:

let
  kernelVersion = "6.12.68";

  kernelSrc = fetchurl {
    url = "mirror://kernel/linux/kernel/v6.x/linux-${kernelVersion}.tar.xz";
    hash = "sha256-02fHUEvU2lIN0B6wgSXS0KwIi8ivTNVtI28gdN1CJbc=";
  };
in
  libkrunfw.overrideAttrs (_old: rec {
    version = "5.2.1";
    inherit kernelSrc;

    src = fetchFromGitHub {
      owner = "containers";
      repo = "libkrunfw";
      tag = "v${version}";
      hash = "sha256-hRu9HEWTyToqntDkqBIvWEn+kAidQdspyWc6Le587qw=";
    };

    postPatch = ''
      substituteInPlace Makefile \
        --replace-fail 'curl $(KERNEL_REMOTE) -o $(KERNEL_TARBALL)' 'ln -s ${kernelSrc} $(KERNEL_TARBALL)'
    '';
  })
