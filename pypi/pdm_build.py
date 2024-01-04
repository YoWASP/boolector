from setuptools_scm.git import parse as parse_git, Configuration


def get_version():
    upstream_git = parse_git("../boolector", config=Configuration.from_file())
    package_git = parse_git("..", config=Configuration.from_file())

    version = f"{upstream_git.tag.major}.{upstream_git.tag.minor}.{upstream_git.tag.micro}"
    if upstream_git.exact: # release
        version += f".0"
    else: # snapshot
        version += f".{upstream_git.distance}"
    version += f".post{package_git.distance}"
    if not upstream_git.exact: # snapshot
        version += f".dev0"
    if upstream_git.dirty or package_git.dirty:
        version += f"+dirty"
    return version


with open("version.txt", "w") as fp:
    fp.write(f"__version__ = \"{get_version()}\"")
