{ libkrunfw, fetchFromGitHub, fetchurl }:

libkrunfw.overrideAttrs (_old: rec {
  version = "5.2.1";

  src = fetchFromGitHub {
    owner = "containers";
    repo = "libkrunfw";
    tag = "v${version}";
    hash = "sha256-hRu9HEWTyToqntDkqBIvWEn+kAidQdspyWc6Le587qw=";
  };

  kernelSrc = fetchurl {
    url = "mirror://kernel/linux/kernel/v6.x/linux-6.12.68.tar.xz";
    hash = "sha256-02fHUEvU2lIN0B6wgSXS0KwIi8ivTNVtI28gdN1CJbc=";
  };
})
