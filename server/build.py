import yaml
from ruamel.yaml import YAML
import subprocess
import time
import logging

# 设置日志配置
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def load_config(filepath="./config.yaml"):
    with open(filepath, "r") as file:
        conf = yaml.safe_load(file)
    logging.info(f"Config: {conf}")
    return conf

def set_proxy(http_proxy, https_proxy):
    commands = [
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

def update_space_agent_config(conf):
    yaml_loader = YAML()
    with open('./space-agent/res/docker-compose_run_as_docker.yml', 'r') as file:
        agent_conf = yaml_loader.load(file)
    for service_name, this_service in agent_conf['services'].items():
        for built_image in conf["services"]:
            if service_name == f"ao{built_image}":
                this_service['image'] = f'local/{built_image}:{conf["tag"]}'
                logging.info(f'Updated image for {service_name} to {this_service["image"]}')
        if service_name == "aospace-nginx":
            this_service['image'] = f'local/space-web:{conf["tag"]}'
            logging.info(f'Updated image for {service_name} to {this_service["image"]}')
    with open('./space-agent/res/docker-compose_run_as_docker.yml', 'w') as newfile:
        yaml_loader.dump(agent_conf, newfile)

def main():
    conf = load_config()
    if conf["whetherproxy"]:
        logging.info("Setting proxy")
        set_proxy(conf["httpproxy_address"], conf["httpsproxy_address"])
    else:
        logging.info("No proxy build mode.")
    
    for service in conf["services"]:
        if service != "space-agent":
            logging.info(f"Building image for {service}/{conf['tag']}")
            build_image(service, conf["tag"])
        else:
            logging.info("Setting for space-agent...")
            update_space_agent_config(conf)
            build_image(service, conf["tag"])

if __name__ == "__main__":
    main()