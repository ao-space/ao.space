import yaml
from ruamel.yaml import YAML
import subprocess
import time
import logging
import argparse
import os

# 设置日志配置
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def load_config(filepath="./config.yaml"):
    with open(filepath, "r") as file:
        conf = yaml.safe_load(file)
    logging.info(f"Config: {conf}")
    return conf

def set_proxy(http_proxy, https_proxy):
    commands = [
        'sudo rm -rf /etc/systemd/system/docker.service.d',
        'sudo mkdir -p /etc/systemd/system/docker.service.d',
        'sudo touch /etc/systemd/system/docker.service.d/http-proxy.conf',
        f'sudo printf "[Service]\nEnvironment=\\"HTTP_PROXY=http://{http_proxy}/\\"\nEnvironment=\\"HTTPS_PROXY=http://{https_proxy}/\\"\nEnvironment=\\"NO_PROXY=localhost,127.0.0.1,localaddress,.localdomain.com\\"" > /etc/systemd/system/docker.service.d/http-proxy.conf',
        'sudo systemctl daemon-reload',
        'sudo systemctl restart docker'
    ]
    for cmd in commands:
        subprocess.run(cmd, shell=True, check=True)
    logging.info("Proxy settings applied successfully")

def build_image(imagename, tag, retries=3, delay=5):
    for attempt in range(retries):
        try:
            logging.info(f"Building image for {imagename}/{tag}, attempt {attempt + 1}")
            subprocess.run(f'sudo docker build -t local/{imagename}:{tag} ./{imagename}', shell=True, check=True)
            logging.info(f"Successfully built {imagename}/{tag}")
            return
        except subprocess.CalledProcessError as e:
            logging.error(f"Failed to build {imagename}/{tag}: {e}")
            if attempt < retries - 1:
                logging.info(f"Retrying in {delay} seconds...")
                time.sleep(delay)
            else:
                logging.error(f"Failed to build {imagename}/{tag} after {retries} attempts")

def run_image(imagename, tag, retries=3, delay=5):
    # 设置 DATADIR 变量
    datadir = os.path.expanduser("~/aospace")
    os.environ["DATADIR"] = datadir

    for attempt in range(retries):
        try:
            logging.info(f"Running image for {imagename}/{tag}, attempt {attempt + 1}")
            
            # 删除现有的 ao-space 网络
            try:
                subprocess.run('sudo docker network rm ao-space', shell=True, check=True)
                logging.info("Existing ao-space network removed.")
            except subprocess.CalledProcessError:
                logging.info("No existing ao-space network found or failed to remove. Continuing...")
            
            # 创建新的 ao-space 网络
            subprocess.run('sudo docker network create ao-space', shell=True, check=True)
            
            # 运行 docker 容器
            subprocess.run(f'''sudo docker run -d --name aospace-all-in-one  \
                --restart always  \
                --network=ao-space  \
                --publish 5678:5678  \
                --publish 127.0.0.1:5680:5680  \
                -v {datadir}:/aospace  \
                -v /var/run/docker.sock:/var/run/docker.sock:ro  \
                -e AOSPACE_DATADIR={datadir} \
                -e RUN_NETWORK_MODE="host"  \
                {imagename}:{tag}''', shell=True, check=True)
            
            logging.info(f"Successfully started {imagename}/{tag}")
            return
        except subprocess.CalledProcessError as e:
            logging.error(f"Failed to run {imagename}/{tag}: {e}")
            if attempt < retries - 1:
                logging.info(f"Retrying in {delay} seconds...")
                time.sleep(delay)
            else:
                logging.error(f"Failed to run {imagename}/{tag} after {retries} attempts")

def update_space_agent_config(conf):
    yaml_loader = YAML()
    with open('./space-agent/res/docker-compose_run_as_docker.yml', 'r') as file:
        agent_conf = yaml_loader.load(file)

    for service_name, this_service in agent_conf['services'].items():
        for built_image, tag in conf.items():
            if service_name == f"ao{built_image}":
                this_service['image'] = f'local/{built_image}:{tag}'
                logging.info(f'Updated image for {service_name} to {this_service["image"]}')
                
        if service_name == "aospace-nginx":
            this_service['image'] = f'local/space-web:{conf.get("space-web", "latest")}'
            logging.info(f'Updated image for {service_name} to {this_service["image"]}')
    
    with open('./space-agent/res/docker-compose_run_as_docker.yml', 'w') as newfile:
        yaml_loader.dump(agent_conf, newfile)

def main():
    conf = load_config()
    parser = argparse.ArgumentParser(description="构建和运行工具")
    subparsers = parser.add_subparsers(dest='command', help='子命令')

    services = conf["services"]
    service_dict = {service: details['tag'] for service, details in services.items()}
    
    # build 子命令
    parser_build = subparsers.add_parser('build', help='构建项目')

      # run 子命令
    parser_run = subparsers.add_parser('run', help='运行项目')

    args = parser.parse_args()
    if args.command == 'build':
        if conf["whetherproxy"]:
            logging.info("Setting proxy")
            set_proxy(conf["httpproxy_address"], conf["httpsproxy_address"])
        else:
            commands = [
            'sudo rm -rf /etc/systemd/system/docker.service.d'
            ]
            for cmd in commands:
                subprocess.run(cmd, shell=True, check=True)
            logging.info("No proxy build mode.")
        for service,tag_number in service_dict.items():
            if service != "space-agent":
                logging.info(f"Building image for {service}/{tag_number}")
                build_image(service, tag_number)
            else:
                logging.info("Setting for space-agent...")
                update_space_agent_config(service_dict)
                build_image(service, tag_number)
    elif args.command == 'run':
        run_image("local/space-agent", service_dict['space-agent'])
    

if __name__ == "__main__":
    main()