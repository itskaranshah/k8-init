# Bootstrap an AWS EKS cluster using *eksctl <https://eksctl.io/>*
 
    $ eksctl create cluster -f cluster.yml
    $ aws eks --region us-east-1 update-kubeconfig --name eks-cluster-1
