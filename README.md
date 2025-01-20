1. 일단 테라폼으로 프로비저닝하면 개인키가 나옵니다.
2. 앤서블 노드에 접속해서 mkdir keypair을 생성하고 해당 디렉토리에 키페어 파일을 넣습니다.
3. chmod 600 tofu-key.pem
4. 이제 /etc/ansible 디렉터리로 가서 위 두개의 파일을 생성합니다.
5. 플레이북 실행 명령  ->   ansible-playbook -i inventory.ini k8s_cluster_setup.yaml
