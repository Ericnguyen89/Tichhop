#!/bin/bash

# Bước 1: Cài đặt Node.js và npm (nếu chưa có)
install_nodejs() {
    if ! [ -x "$(command -v node)" ]; then
        echo "Installing Node.js..."
        curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
        sudo apt-get install -y nodejs
        echo "Node.js installed successfully."
    else
        echo "Node.js is already installed."
    fi
}

# Bước 2: Tạo thư mục cho máy chủ quản lý license
create_server_directory() {
    if [ ! -d "license-server" ]; then
        echo "Creating directory for license server..."
        mkdir -p license-server
        cd license-server
        echo "Directory created successfully."
    else
        echo "Directory for license server already exists."
    fi
}

# Bước 3: Tạo package.json cho dự án Node.js
create_package_json() {
    if [ ! -f "package.json" ]; then
        echo "Creating package.json..."
        npm init -y
        echo "package.json created successfully."
    else
        echo "package.json already exists."
    fi
}

# Bước 4: Cài đặt các gói phụ thuộc
install_dependencies() {
    echo "Installing dependencies..."
    npm install express body-parser
    echo "Dependencies installed successfully."
}

# Bước 5: Viết mã cho máy chủ quản lý license
write_server_code() {
    cat <<'EOF' > server.js
const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const PORT = 3000;

// Mock database of issued license keys
const licenses = new Map();

app.use(bodyParser.json());

// Endpoint to validate a license key
app.post('/validate-license', (req, res) => {
    const { licenseKey } = req.body;
    if (licenses.has(licenseKey)) {
        const license = licenses.get(licenseKey);
        if (license.expires > Date.now()) {
            res.json({ valid: true, message: 'License is valid.' });
        } else {
            res.json({ valid: false, message: 'License has expired.' });
        }
    } else {
        res.json({ valid: false, message: 'Invalid license key.' });
    }
});

// Start the server
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
EOF
    echo "Server code written successfully."
}

# Bước 6: Chạy máy chủ
start_server() {
    echo "Starting license server..."
    node server.js &
    echo "License server started successfully."
}
create_license() {
    echo "Creating license key..."

    # Nhập thông tin từ người dùng
    read -p "Enter customer name: " customer_name
    read -p "Enter customer email: " email
    read -p "Enter expiration date (YYYY-MM-DD): " expiration_date

    # Gửi yêu cầu tạo license key
    local response=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"customerName\": \"$customer_name\", \"email\": \"$email\", \"expirationDate\": \"$expiration_date\"}" http://localhost:3000/generate-license)
    local license_key=$(echo $response | jq -r '.licenseKey')

    echo "License key created successfully: $license_key"
}
# Chạy các hàm theo thứ tự
install_nodejs
create_server_directory
create_package_json
install_dependencies
write_server_code
start_server
create_license

echo "License server installation completed successfully."
