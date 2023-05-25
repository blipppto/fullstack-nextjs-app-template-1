# Full-Stack Next.js Application Template

This repository is a full-stack sample web application based on Next.js that creates a simple whole-website architecture, and provides the foundational services, components, and plumbing needed to get a basic web application up and running.

![quick overview](public/assets/images/screenshot.jpg)

## Table of Contents

- [Creating an Instance on Digital Ocean](#creating-an-instance-on-digital-ocean)
- [Installing Docker](#installing-docker)
- [Containerize the application and push it to docker hub](#containerize-the-application-and-push-it-to-docker-hub)
- [Generate API Token](#generate-api-token)
- [Deploy Image on Kubernetes](#deploy-image-on-kubernetes)
- [Deploying the Container on Azure](#deploying-the-container-on-azure)
- [Contributing](#contributing)
- [Supported development environment](#supported-development-environment)
- [Licensing](#licensing)

## Creating an Instance on Digital Ocean

1. Create a digital ocean account and log into it. Then click on create new project. If you have an existing one you may skip this step
   ![create project](readme_pics/create_project.png)

1. Enter the name of your project, a description and what it is going to be used for then click on create project. I already have a project so I will just be using my project called first project. Enter into your project and click on create at the top right of the screen. A drop down menu will appear. Click on create droplet.
   ![create project](readme_pics/create_droplet.png)

1. Choose the region closest to you, I will be choosing Frankfurt for this tutorial and will be using an ubuntu image with version 20.04(LTS)x64, select the following options:

- Droplet type - Basic
- CPU options - Regular [1GB/1CPU, 25GB SSD Disk, 1000GB transfer]
- Authentication method: Password (would be better to use ssh key, but for simplification of this tutorial I'd use password however if you have an ssk key you can add it )
  ![create project](readme_pics/final_create_droplet.png)
  Click on the droplet you just created and on the extreme right click on console.
  ![create project](readme_pics/click_console.png)
  A window should be opened which looks like this
  ![create project](readme_pics/cli.png)

## Installing Docker

1. create a new file called script.sh using the command

```sh
 vim script.sh
```

2. copy the contents of the bash script below
   and paste it there using `cntrl + shift + v` or right clicking and selecting paste

```bash

#!/bin/bash

echo "***********************updating system*********************************************************************************************************"
sudo apt update
echo "***********************upgrading system**********************************************************************************************"
sudo apt upgrade -y
echo "***********************removing old docker***********************************************************************************************"
sudo apt-get remove docker docker-engine docker.io containerd runc
echo "***********************removing old docker******************************************************************************************"
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
echo "***********************Add GPG key******************************************************************************************************"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
echo "***********************add docker repo***********************************************************************************************"
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
echo "***********************specify installation source*************************************************************************************"
apt-cache policy docker-ce
echo "***********************installing docker*********************************************************************************************"
sudo apt install docker-ce -y
echo "***********************check docker status************************************************************************************************"
echo "***********************add docker to group************************************************************************************************"
sudo usermod -aG docker $USER

```

## Containerize the application and push it to docker hub

1. You will need to clone the application to your server. Run the code below to do that.

```sh
git clone https://github.com/blipppto/fullstack-nextjs-app-template-1.git
```

2. Log into your docker account. If you do not have an account with docker hub you can create one [Here](https://hub.docker.com/). When you are done, run this code on your server

```ssh
docker login
```

input your docker username and password in the prompt that comes up

3.  Enter into the application, then build, run and push your image. The format to build your docker file is

`docker build -t <name of file>:version`

and the format to tag and push

`docker tag <name of image>:<version> <repository>:<version>`

`docker push <repository>`

The name of the file used in this tutorial will be called chizidockerizedapp and I am going to use version 1.0. Don't forget to change your repository name!!.

```sh
cd fullstack-nextjs-app-template-1.git

docker build -t chizidockerizedapp:1.0

docker tag chizidockerizedapp:1.0 <repository>:latest

docker push <repository>

```

## Generate API Token

1. Get API details. To do this, on the digital ocean console click on API at the bottom left and click on generate new token.

![Generate token](readme_pics/token.png)

A pop up will come up asking you to input token name, expiration and scope. Ensure you check the write option for the scope. You can use any name you like for the token.
![Generate token](readme_pics/token2.png)
Then click on generate token and copy your token and keep it in a safe place. Note, the token usually begins with dop_v1

## Deploy Image on Kubernetes

1. Create a new document called script2.sh using the command

```bash
vim script2.sh
```

Copy and paste the bash script command below by using `cntrl + C` to copy it on this github page and `cntrl + shift + v` to paste it in the vim editor. Then type `:wq` to save and exit the editor

```vim
#!/bin/bash

sudo apt update
sudo apt upgrade -y
echo "*******************************************************installing doctl**************************************************************"
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.94.0/doctl-1.94.0-linux-amd64.tar.gz
tar xf ~/doctl-1.94.0-linux-amd64.tar.gz
sudo mv ~/doctl /usr/local/bin
echo "**************************************put authentication details****************************************"
doctl auth init
doctl auth list
echo "*********************************************************install kubectl*********************************************************************"
curl -LO "https://dl.k8s.io/release/v1.26.3/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client
echo "*********************************************************creating cluster*********************************************************************"
doctl kubernetes cluster create shecode --tag do-tutorial --auto-upgrade=true --node-pool "name=shecode;count=1;auto-scale=true;min-nodes=1;max-nodes=2;tag=do-tutorial"
doctl kubernetes cluster kubeconfig save shecode
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.0/deploy/static/provider/do/deploy.yaml

```

write this code to run the script

```
bash script2.sh
```

Note that during the running of this code you will be asked to put your token like in the picture below and if you get any prompt concerning openssh just click on enter and proceed.

![Generate token](readme_pics/authentication.png)

Also you can change your cluster name by replacing shecode with your desired name under the creating cluster section in the script which you can identify with asterics infront and behind the words _creating cluster_, such as below

`***********creating cluster*********`

You are almost done. All that is remaining is to create and run your kubernetes deployment file. to create your deployment file run

```bash
vim deployment.yaml
```

Then paste the content of the deployment file using `cntrl + shift + v`

if you do not have a domain name use this deployment file. You may change the image to your own image which you pushed on docker hub

```vim
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: shecode
          image: blipppto/chizidockerizedapp:1.0
          ports:
            - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: shecode-service
spec:
  selector:
    app: my-app
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000
      nodePort: 30000
```

If you have a domain name you should use this deployment file. You may change the image to your own image which you pushed on docker hub. Dont forget tp change your host name (which is shecode.chizi.me in the script below) to your actual domain name.

```bash

apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: shecode
          image: blipppto/chizidockerizedapp:1.0
          ports:
            - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: shecode-service
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shecode-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: shecode.chizi.me
    http:
      paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: shecode-service
                port:
                  number: 3000

```

To run the deployment, use the code below

```
kubectl apply -f deployment.yaml
```

To check the IP address which the container is running on, use the code below

```
kubectl get service
```

If you ran the deployment file that does not require a domain name, you will see the external IP address of shecode-service and its port. Go to a new tab in your browser input `<the external IP Address>:<portnumber>` and your service is deployed

However if you ran the deployment file that requires a domain name the you should run

```
kubectl get ingress
```

copy the ip address associated with your ingress. In this case shecode-ingress

edit your /etc/hosts file by using the command

```
vim /etc/hosts
```

press i on your keyboard to be able to edit it. at the bottom of the file add these lines

```
<ip address> <domain name>
www.< ip address> <domanin name>
```

It should be similar to the picture below
![Generate token](readme_pics/etchosts.png)

Finally go to your webhosting site and add your domain name record



## Deploying the Container on Azure

Login to your azure account and search for ``virtual machine`` on the search bar then click on virtual machine
click on the create button by the top left and select azure virtual machine to create a new vm 
![Generate token](readme_pics/createvirtualmachine.png)
In your virtal machine you can use azure default subscription or use a new one we are going to use the default. you can choose to create a new resource group or use an existing one,
choose your availability options. I will pick avalability zone, zone 1
security type: trusted launch virtual machine
image: ubuntu server 20.04 LTS -x64 (Gen2)
size: Standard_B1s - 1vcpu 1GiB memory
authentication type -ssh
ssh public key source - generate a new public key
use any name for your key pair name
public inbound port: allow selected ports
select inbound ports: http(80) https (443) and ssh(22)
click ``next : disk`` and leave the defalt settings but ensure delete with vm is ticked. Click on ``next: Networking``
ensure this is ticked Delete public IP and NIC when VM is deleted
Leave everything else at default settings then click on ``review and create`` and create your vm 

click on the newly created vm and click o connect and follow the instructions to connect to your vm

In your vm run the script below by creating a file and copying and pasting it into it by doing the following

```
vim azurescript.sh
```
then copy the script from this page and right click and select paste to paste it into the vm. type `:wq` to save and close the document
```bash
 #!/bin/bash

 sudo apt update
 sudo apt upgrade -y
 echo "**********installing azurecli*************************"
 curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
 echo "********installing kubectl*************************"
curl -LO "https://dl.k8s.io/release/v1.26.3/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client
echo "**********************login to azure account a***************"
az login
# if you have mutltiple subscriptions you can uncomment the line below
#az account set --subscription <subscription name>

echo "*********************creating cluster and connect it with vm***********************************"
# to list locations use
# az account list-locations --output table
# if you have an existing ssh key you wantto use, use the next line
# az aks create --resource-group <resource_group_name> --name <cluster_name> --node-count <node_count> --location <location> --ssh-key-value <public_key_file>
az aks create --resource-group conny --name shecode --node-count 2 --location southafricanorth --generate-ssh-keys
az aks get-credentials --resource-group conny --name shecode
# SSH key files '/home/azureuser/.ssh/id_rsa' and '/home/azureuser/.ssh/id_rsa.pub' have been generated under ~/.ssh to allow SSH access to the VM. If using machines without permanent storage like Azure Cloud Shell without an attached file share, back up your keys to a safe location
echo "*********************installing nginx-controller*********************"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.0/deploy/static/provider/do/deploy.yaml

```
The script above was to install azure cli, kubectl, login to azure, create a cluster named shecode and connect the cluster with the virtual machine. You will definitely get a prompt asking you to put your login details during the running of this script. Then continue from here(if-you-do-not-have- a-domain-name) 

You are almost done. All that is remaining is to create and run your kubernetes deployment file. to create your deployment file run

```bash
vim deployment.yaml
```

Then paste the content of the deployment file using `cntrl + shift + v`

if you do not have a domain name use this deployment file. You may change the image to your own image which you pushed on docker hub

```vim
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: shecode
          image: blipppto/chizidockerizedapp:1.0
          ports:
            - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: shecode-service
spec:
  selector:
    app: my-app
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000
      nodePort: 30000
```

If you have a domain name you should use this deployment file. You may change the image to your own image which you pushed on docker hub. Dont forget tp change your host name (which is shecode.chizi.me in the script below) to your actual domain name.

```bash

apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: shecode
          image: blipppto/chizidockerizedapp:1.0
          ports:
            - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: shecode-service
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shecode-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: shecode.chizi.me
    http:
      paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: shecode-service
                port:
                  number: 3000

```

To run the deployment, use the code below

```
kubectl apply -f deployment.yaml
```

To check the IP address which the container is running on, use the code below

```
kubectl get service
```

If you ran the deployment file that does not require a domain name, you will see the external IP address of shecode-service and its port. Go to a new tab in your browser input `<the external IP Address>:<portnumber>` and your service is deployed

However if you ran the deployment file that requires a domain name the you should run

```
kubectl get ingress
```

copy the ip address associated with your ingress. In this case shecode-ingress

edit your /etc/hosts file by using the command

```
vim /etc/hosts
```

press i on your keyboard to be able to edit it. at the bottom of the file add these lines

```
<ip address> <domain name>
```

It should be similar to the picture below
![Generate token](readme_pics/azureetchosts.png)

Finally go to your webhosting site and add your domain name record



## Contributing

- [React](https://reactjs.org/)
- [nextjs](https://nextjs.org/)
- [redux](https://redux.js.org/)
- [axios](https://github.com/axios/axios)
- [Express](http://expressjs.com/)
- [php-express](https://github.com/fnobi/php-express)
- [next-cookies](https://github.com/matthewmueller/next-cookies)
- [pm2](https://pm2.keymetrics.io/)

## Supported development environment

- Next.js 13.x +
- React 18 +
- TypeScript 4.x.x +
- Express 4.x.x

## Licensing

Licensed under the [MIT](https://opensource.org/licenses/MIT).
