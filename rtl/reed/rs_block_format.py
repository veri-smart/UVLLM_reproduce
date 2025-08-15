if __name__ == "__main__":
    with open("input_RS_blocks", "r") as fin:
        lines = fin.readlines()
    result = []
    for l in lines:
        l = l.strip('\n').strip()
        if not l:
            continue
        x = 0
        for i in range(8):
            x <<= 1
            if l[i] == '1':
                x |= 1
        result.append(x)
    with open("input_RS_blocks_formatted", "w") as fout:
        fout.write(", ".join(map(lambda x: str(x), result)))
        

