YoWASP Boolector package
========================

This package provides [Boolector][] binaries built for [WebAssembly][]. See the [overview of the YoWASP project][yowasp] for details.

[boolector]: https://github.com/Boolector/boolector
[webassembly]: https://webassembly.org/
[yowasp]: https://yowasp.github.io/


Versioning
----------

The version of this package is derived from the upstream boolector package version in the ``X.Y[.Z]`` format, and is comprised of five or six parts in a ``X.Y.Z.N.postM[.dev0]`` format:

1. ``X``: boolector major version
2. ``Y``: boolector minor version
3. ``Z``: boolector patch version
4. ``N``: zero for packages built from boolector releases, ``N`` for packages built from unreleased boolector snapshots; ``N`` is the amount of commits since the latest release
5. ``postM``: package build version; disambiguates different builds produced from the same boolector source tree
6. ``dev0``: present only for packages built from unreleased boolector snapshots; marks these packages as pre-releases.

With this scheme, there is a direct correspondence between upstream versions and [PEP 440][pep440] Python package versions.

[pep440]: https://peps.python.org/pep-0440/


Configuration
-------------

See the documentation for [the Python YoWASP runtime](https://github.com/YoWASP/runtime-py#configuration).


License
-------

This package is covered by the [MIT license](LICENSE.txt), which is the same as the [Boolector license](https://github.com/Boolector/boolector/blob/master/COPYING).
