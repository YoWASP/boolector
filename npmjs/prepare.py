import re
import json
import subprocess


boolector_version_raw = subprocess.check_output([
    "git", "-C", "../boolector-src", "describe", "--tags", "HEAD"
], encoding="utf-8").strip()

git_rev_list_raw = subprocess.check_output([
    "git", "rev-list", "HEAD"
], encoding="utf-8").split()

boolector_version = re.match(r"^(\d+).(\d+).(\d+)(?:-(\d+)-)?", boolector_version_raw)
boolector_major   = int(boolector_version[1])
boolector_minor   = int(boolector_version[2])
boolector_patch   = int(boolector_version[3])
boolector_node    = int(boolector_version[4] or "0")

distance = len(git_rev_list_raw) - 1

version = f"{boolector_major}.{boolector_minor}.{boolector_patch}-{boolector_node}.{distance}"
print(f"version {version}")

with open("package-in.json", "rt") as f:
    package_json = json.load(f)
package_json["version"] = version
with open("package.json", "wt") as f:
    json.dump(package_json, f, indent=2)
