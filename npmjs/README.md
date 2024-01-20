YoWASP Boolector package
========================

This package provides [Boolector][] binaries built for [WebAssembly][]. See the [overview of the YoWASP project][yowasp] for details.

At the moment, this package only provides an API allowing to run Boolector in a virtual filesystem; no binaries are provided.

[boolector]: https://boolector.github.io/
[webassembly]: https://webassembly.org/
[yowasp]: https://yowasp.github.io/


API reference
-------------

This package provides one function:

- `runBoolector`

For more detail, see the documentation for [the JavaScript YoWASP runtime](https://github.com/YoWASP/runtime-js#api-reference).


Versioning
----------

The version of this package is derived from the upstream Boolector package version in the `X.Y.Z-N.M` format, where the symbols are:

1. `X`: Boolector major version
2. `Y`: Boolector minor version
3. `Z`: Boolector patch version
4. `N`: zero for packages built from boolector releases, ``N`` for packages built from unreleased boolector snapshots; ``N`` is the amount of commits since the latest release
5. `M`: package build version; disambiguates different builds produced from the same Boolector source tree

With this scheme, there is a direct correspondence between upstream versions and [SemVer][semver] NPM package versions.

[semver]: https://semver.org/


License
-------

This package is covered by the [MIT license](LICENSE.txt), which is the same as the [Boolector license](https://github.com/Boolector/boolector/blob/master/COPYING).
