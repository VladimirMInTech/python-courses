def main():
    output = {}
    count_str = {}
    with open("dataset_3380_5.txt") as input_file:
        for line in input_file:
            l = line.split()
            scool_class, second_name, height = l[0], l[1], l[2]

            if scool_class not in output:
                output[scool_class] = 0
                count_str[scool_class] = 0
            output[scool_class] += int(height)
            count_str[scool_class] += 1

    with open('output.txt', 'w') as output_file:
        for i in range(1,12):
            key = str(i)
            value = output.get(key)
            count = count_str.get(key)
            if value is not None:
                output_file.write(f"{i} {float(value/count)}\n")
            else:
                output_file.write("{i} -\n")

if __name__ == "__main__":
    main()

