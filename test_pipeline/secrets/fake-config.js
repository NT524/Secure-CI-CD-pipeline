// Bẫy Gitleaks: AWS Secret Access Key giả mạo
const aws_config = {
    accessKeyId: "AKIAIOSFODNN7EXAMPLE",
    secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
    region: "us-east-1"
};

// Bẫy Semgrep: Sử dụng hàm băm (hash) lỗi thời và yếu
const crypto = require('crypto');
function hashPassword(password) {
    // Semgrep sẽ cảnh báo vì MD5 rất dễ bị tấn công collision
    return crypto.createHash('md5').update(password).digest('hex'); 
}

module.exports = { aws_config, hashPassword };