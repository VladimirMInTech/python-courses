def main():
    count_words = int(input())
    access_words = []
    verification_words = []
    input_words = []
    for i in range(count_words):
        access_words.append(str(input()).lower())
    str_for_verification = int(input())

    for i in range(str_for_verification):
        input_words += str(input()).lower().split()

    for word in input_words:
        if word not in verification_words:
            verification_words.append(word)

    for i in verification_words:
        if i not in access_words:
            print(i)


if __name__ == "__main__":
    main()
