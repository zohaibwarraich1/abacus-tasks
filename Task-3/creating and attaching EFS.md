# Task: Create and attach efs to ASG servers for persistent storage and sharable file system that will be helpful in auto scaling and data recovery.

## Creating Filesystem

- File system type: Regional
- Automatic backups: Enabled ✅
- Lifecycle management
    * Transition into Infrequent Access (IA): 30 days
    * Transition into Archive: 90 days
    * Transition into Standard: None
- Encryption: Enabled ✅
- Throughput mode: Enhanced & Elastic
- Network: VPC -> Project abacus task vpc
- Create Security group for efs and allow NFS traffic (TCP Port 2049) from Security group of ASG servers.
- Mount targets: 
    - Availability Zone: ap-south-1a
        - Subnet: private 1a
        - Security group: efs-sg
    - Availability Zone: ap-south-1b
        - Subnet: private 1b
        - Security group: efs-sg
- Policy: Prevent root access by default

## Configure mount targets

1. Install the efs helper on Servers
    ```yaml
    sudo apt update
    sudo apt install -y nfs-common
    
    # Following are if you want to use amazon-efs-utils (recommended with TLS support)
    
    sudo apt update 
    sudo apt install -y git binutils
    git clone https://github.com/aws/efs-utils
    cd efs-utils
    ./build-deb.sh

    # Note: If you are using amazon-efs-utils, 
    # you need to install cargo and rustc first
    sudo apt install -y cargo rustc

    sudo apt install -y ./build/amazon-efs-utils*.deb
    ```
2. Run mount commands on server
    ```yaml
    sudo mkdir /var/abacus-projects  # Creates mount point

    sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-0f401712e86f14aab.efs.ap-south-1.amazonaws.com:/ /var/abacus-projects  # Mounts EFS to the EC2 instance using NFS Client
    ```

3. To permanently mount the efs whenever the system reboots:
    ```yaml
    sudo vi /etc/fstab
    ```
    Add the following line to the end of the file:
    ```yaml
    fs-0f401712e86f14aab.efs.ap-south-1.amazonaws.com:/ /var/abacus-projects nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0
    ```
    By doing so, whenever the system reboots it will automatically mount the efs to the /var/abacus-projects directory.
    
    * _netdev : This option tells the system to wait for the network to be available before attempting to mount the file system because mounting requires network connection.

