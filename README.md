
## Pre-requisites

1. Create a S3 buckets with unique names. The buckets will store the Terraform state. The name of
the buckets should start with <env-name>-<unique-bucket-name>

2. Install Ansible and Terraform. You can skip this if its already installed.

    terraform: 
    
    sudo yum install -y yum-utils
    
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    
    sudo yum -y install terraform
    
    ansible:
    
    sudo yum install ansible -y
    ansible --version
    
    sudo yum install python-boto3

if the commands above don't work, then find a different option to install terraform and ansible.


## Deployment Process

1. After cloning the repository, create 3 terminals. You should be in the /environment for all 3. Use the command to access each directory.
    
    1 terminal for network: 

        cd acs730_final_project/prod/network/
        
    1 terminal for webservers: 
    
        cd acs730_final_project/prod/webservers/
        
    1 terminal for ansible:
    
        cd acs730_final_project/ansible/


2. Update the config.tf file in both the prod/network and prod/webservers with the bucket that you made. 

3. In prod/webservers/main.tf file, change the bucket name of data "terraform_remote_state" block to the bucket you made.

4. Create a new terminal:
    
    cd acs730_final_project/keys/production

    then generate a ssh key using the command:
    
    ssh-keygen -t rsa -f prod
    
    you can also delete the placeholder.txt file. or leave it be.


5. In the network terminal initialize terraform and run to apply.

    alias tf=terraform
    tf init
    tf fmt
    tf validate
    tf plan
    tf apply --auto-approve
    
6. In the webserver terminal do the same thing as network. 

    alias tf=terraform
    tf init
    tf fmt
    tf validate
    tf plan
    tf apply --auto-approve
    
    Remember that the network should always be deployed before the webserver.

7. Now after deploying the infrastructure, go the webserver terminal and ssh into the bastion host (prod-webserver-2)
    
    ssh -i /home/ec2-user/environment/project/keys/production/prod ec2-user@<bastion-ip>
    
    exit and copy the private key into the bastion host server.

    scp -i /home/ec2-user/environment/project/keys/production/prod /home/ec2-user/environment/project/keys/production/prod ec2-user@<bastion-ip>:/home/ec2-user

8. Now ssh back into bastion host again and type in ls. you should see a file called 'prod'. 
   While inside bastion host test to connect to the private webservers and see it can connect to the internet.

    ssh -i prod ec2-user@<prod-webserver5-ip>
    
    after you ssh into the private webserver (prod-webserver-5),
    
    curl localhost
    
    after seeing a response, exit.
    
    Then try the process again for the other private webserver (prod-webserver-6).
    
9. Now inside the ansible directory, open the aws_ec2.yaml file. Then under the filter for instance-id: replace the instance ID with webservers 3 & 4. (prod-webserver-3, and prod-webserver-4)

10. Go to the terminal with the ansible directory. Then check to see if the ansible configuration file is empty.

    sudo vi /etc/ansible/ansible.cfg
    
    make sure it has the content below inside.
    
    [defaults]
    host_key_checking = false
    inventory = /home/ec2-user/environment/project/ansible/aws_ec2.yaml
    ansible_user = ec2-user 
    ansible_ssh_private_key_file = /home/ec2-user/environment/project/keys/production/prod
    [inventory]
    enable_plugins = aws_ec2
    
    then exit the ansible config file.
    
11. On the ansible terminal, type in the command 

    ansible-inventory --graph -i aws_ec2.yaml (optional) to see the groups.
    
    ansible-playbook -i aws_ec2.yaml playbook3.yaml (to run the playbook)
    
12. After confirming or doing whatever is needed on the infrastructure, we destroy it.

13. Move to the webserver terminal and type in the command:

     tf destroy --auto-approve
     
     and wait till it is done.
     
14. After the webserver terminal is finished destroying the infrastructure, move to the network terminal and destroy the infrastructure using the same command.
 
     tf destroy --auto-approve





## AWS Actions

Once you deployed the infrastructure for both prod/network and prod/webserver, we do some tasks.


1. Use the webserver-2 to act as our bastion host to connect to the private webservers 5 & 6 and show that it has connection to the internet and downloaded apache. We can just do "curl localhost" after sucessfully connecting to the private webservers.
2. Check if the load balancer is working correctly by using the DNS link. We simulate server failure by stopping one of the public webservers (1-4) and showing that the remaining 3 will still function. Start the "stopped" webserver after the check.
3. Use the ansible playbook to configure some changes to the webserver. Then on the load balancer DNS page, refresh to show that the changes were successfully and working properly for the configured webservers.