def main():
    count_command = int(input())
    x = y = 0
    for _ in range(count_command):
        direction, distance = input().split()
        if direction == "восток":
            x += int(distance)
        elif direction == "запад":
            x -= int(distance)
        elif direction == "север":
            y += int(distance)
        else:
            y -= int(distance)
    print(int(x), int(y))

def main2():
    count_command = int(input())
    d = {"север": 0, "юг": 0, "восток": 0, "запад": 0}
    for i in range(count_command):
        input_str = input().split()
        d[input_str[0]] += int(input_str[1])
    # print(d['восток']-d['запад'], d['север'] - d['юг'])
    print(d['восток']-d['запад'],d['север'] - d['юг'], sep=' ')

if __name__ == "__main__":
    # main()
    main2()