def main():
    original_str = str(input())
    cipher = str(input())
    encrypt_str = str(input())
    decrypt_str = str(input())

    encrypted_str = decrypted_str = ""

    if len(original_str) != len(cipher):
        return print("Len original string != len cipher")

    code = {original_str[i]: cipher[i] for i in range(len(original_str))}
    reverse_code = {cipher[i]: original_str[i] for i in range(len(original_str))}

    encrypted_str = ''.join(code.get(i, i) for i in encrypt_str)
    decrypted_str = ''.join(reverse_code.get(j, j) for j in decrypt_str)

    print(encrypted_str)
    print(decrypted_str)


if __name__ == "__main__":
    main()
