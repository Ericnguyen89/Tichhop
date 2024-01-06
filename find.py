import os

def search_files(directory, content_to_search):
    for root, dirs, files in os.walk(directory):
        for file in files:
            file_path = os.path.join(root, file)
            try:
                with open(file_path, 'r') as f:
                    file_content = f.read()
                    if content_to_search in file_content:
                        print(f"\n ---------------------------\n FILE FOUND: {file_path}\n--------------------------------\n")
            except Exception as e:
                print(f"Error reading file {file_path}: {str(e)}")

# Người dùng nhập đường dẫn thư mục và nội dung tìm kiếm
search_directory = input("Enter the directory path to search: ")
content_to_search = input("Enter the content to search: ")

# Kiểm tra xem đường dẫn tồn tại hay không
if os.path.exists(search_directory):
    search_files(search_directory, content_to_search)
else:
    print("Invalid directory path. Please enter a valid path.")
