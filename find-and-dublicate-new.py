import os
import shutil

def clone_and_rename_files(directory, keyword):
    for root, _, files in os.walk(directory):
        for file_name in files:
            if keyword in file_name:
                original_path = os.path.join(root, file_name)
                new_file_name = file_name.replace(keyword, change_new)
                new_path = os.path.join(root, new_file_name)
                
                shutil.copyfile(original_path, new_path)
                print(f"Đã nhân bản và đổi tên file: {file_name} thành {new_file_name}")

# Lấy từ khóa từ người dùng
keyword = input("Nhập tên gốc muốn đổi: ")
directory = input("Nhập đường dẫn thư mục: ")
change_new = input("Nhập tên mới muốn đổi: ")

clone_and_rename_files(directory, keyword)
