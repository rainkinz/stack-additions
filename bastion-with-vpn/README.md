# Configuring and starting the VPN

## 1. Initialize the PKI

```sh
$ script/ovpn-init
```

## 2. Start the server

```sh
$ script/ovpn-start
```

## 3. Generate the Client Certificate

```sh
$ script/ovpn-new-client $USER
```

## 4. Download OpenVPN client configuration

```sh
$ script/ovpn-client-config $USER
```

Note to connect to the docker container running openvpn use:

```sh
$ docker run --volumes-from ovpn-data --rm --interactive --tty gosuri/openvpn /bin/sh
```


# SSHing into the various instances

Add the key to the agent:

```sh
ssh-add ssh/insecure-deployer
```

Check they're added:

```sh
ssh-add -l
2048 SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX /Users/brendan/.ssh/id_rsa (RSA)
2048 SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ssh/insecure-deployer (RSA)
```

```sh
ssh -At -i ssh/insecure-deployer "ec2-user@$(terraform output nat.dns)" ssh  "ubuntu@$(terraform output app.0.ip)"
```


* Terraform Example: `ebs_block_device` that remains after instance termination
https://gist.github.com/phinze/6610c1dd727ccfdb810a



* Debugging:

```sh
aws --profile docker ec2 run-instances --image-id ami-2b594f41 --count 1 --key-name aws-docker --instance-type t2.micro --user-data file://cloud-config/test.yml --security-group-ids sg-45e1023e --subnet-id subnet-d09ed4a6
```
