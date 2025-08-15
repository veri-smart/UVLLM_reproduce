from pathlib import Path
import argparse
import os
import re
import subprocess

def do_strip(path: os.PathLike, out: os.PathLike | None):
    if not str(path)[-2:] == ".v":
        return
    result = subprocess.run(["verible-verilog-preprocessor", "strip-comments", path], capture_output=True, text=True)
    if result.returncode != 0:
        print(result)
        exit(1)
    if out:
        out_path = out
    else:
        out_path = path
    lines = result.stdout.splitlines()
    lines2 = []
    for l in lines:
        l = l.rstrip() 
        if not lines2 and l:
            lines2.append(l)
        elif lines2 and (l or lines2[-1]):
            lines2.append(l)
        
    result = subprocess.run(["verible-verilog-format", "-"], input="\n".join(lines2), capture_output=True, text=True)
    if result.returncode != 0:
        print(result)
        exit(1)

    with open(out_path, "w") as fout:
        fout.write(result.stdout)

if __name__ == "__main__":
    parser = argparse.ArgumentParser("strip_comment")
    parser.add_argument("path", type=Path)
    parser.add_argument("--out", '-o', type=Path)

    args = parser.parse_args()

    if os.path.isfile(args.path):
        do_strip(args.path, getattr(args, "out", None))
    elif os.path.isdir(args.path):
        for root, dirs, files in os.walk(args.path):
            if args.out:
                rel = os.path.relpath(root, args.path)        
                for f in files:
                    do_strip(os.path.join(root, f), os.path.join(rel, f))
            else:
                for f in files:
                    do_strip(os.path.join(root, f), None)
    else:
        raise argparse.ArgumentError("path should be a file or a dir!")
