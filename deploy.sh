#!/bin/bash
set -e

echo "🚀 Terraform apply..."
cd terraform
terraform init
terraform apply -auto-approve

EC2_IP=$(terraform output -raw ec2_public_ip)
KEY_PATH=$(terraform output -raw private_key_path)

echo "✅ EC2 Public IP: $EC2_IP"
echo "🔑 Key Path: $KEY_PATH"

cd ..

echo "⏳ Waiting for instance SSH to be ready..."
sleep 20

echo "📝 Generating Ansible inventory..."
cat > ansible/inventory.ini <<EOF
[web]
$EC2_IP ansible_user=ubuntu ansible_ssh_private_key_file=$KEY_PATH
EOF

echo "⚙️ Running Ansible playbook..."
cd ansible
ansible-playbook -i inventory.ini playbook.yml

echo "🎉 Done. Open: http://$EC2_IP"
