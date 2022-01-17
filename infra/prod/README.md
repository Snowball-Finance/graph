# Blockchain nodes

these blockchain nodes are being deployed using terraform and ansible to download the necessary tools/packages
thus because when installing theres some steps to take you still need to ssh into the machine and run `./avalanchego-installer.sh` and choose
the the platform where the node is going to run, but other than that it the ansible and terraform takes care of.

## generate the `inventory.yaml` file:
To generate the ansible inventory run `terraform apply` this will output both the ssh key as well the `inventory.yaml` file

## EC2 Instance connect: 
For any dev to connect to these instances they must be in the `prod-snowball-user-group` IAM group, since
we have switched to use `instance-connect` for better security.
You need to have `AWSCLI` installed as well as a profile defined.
To send your `ssh` key to the instance  run: 
```bash 
aws --profile <aws-profile> ec2-instance-connect send-ssh-public-key --region <region> \ 
--instance-id <instance-id> --availability-zone <zone> --instance-os-user <user>  \ 
--ssh-public-key file://<your_pub_key>
```

example:
```bash
aws --profile snowball ec2-instance-connect send-ssh-public-key --region us-west-2 \ 
--instance-id i-04fe5cf8571ed709e --availability-zone us-west-2a --instance-os-user ubuntu \ 
--ssh-public-key file://.ssh/snowball.pub.pub
```