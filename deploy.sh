#!/bin/bash
set -e

echo "🚀 Terraform apply..."
cd terraform
terraform init
terraform apply -auto-approve

EC2_IP=$(terraform output -raw ec2_public_ip)
KEY_PATH=$(terraform output -raw private_key_path)

# Convert relative key path to absolute path
KEY_PATH=$(realpath "$KEY_PATH")

# Fix permissions (SSH will reject if too open)
chmod 400 "$KEY_PATH"

echo "✅ EC2 Public IP: $EC2_IP"
echo "🔑 Key Path: $KEY_PATH"

cd ..

echo "⏳ Waiting for instance SSH to be ready..."
sleep 20

echo "📝 Generating Ansible inventory..."
cat > ansible/inventory.ini <<EOF
[web]
$EC2_IP ansible_user=ec2-user ansible_ssh_private_key_file=$KEY_PATH ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

echo "⚙️ Running Ansible playbook..."
cd ansible
ansible-playbook -i inventory.ini playbook.yml

echo "🎉 Done. Open: http://$EC2_IP"
