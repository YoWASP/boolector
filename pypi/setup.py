from setuptools import setup
from setuptools_scm.git import parse as parse_git


def get_version():
    upstream_git = parse_git("../boolector-src")
    package_git = parse_git("..")

    version = f"{upstream_git.tag.major}.{upstream_git.tag.minor}.{upstream_git.tag.micro}"
    if upstream_git.exact: # release
        version += f".0"
    else: # snapshot
        version += f".{upstream_git.distance}"
    version += f".post{package_git.distance}"
    if not upstream_git.exact: # snapshot
        version += f".dev0"
    # FIXME: uncomment this once dependencies are no longer patched
    # if package_git.dirty or upstream_git.dirty:
    #     version += f"+dirty"
    return version


setup(
    version=get_version(),
)
