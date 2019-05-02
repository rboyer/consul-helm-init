You should mostly be able to copy `config.vars.bash.example` to
`config.vars.bash`, fill in the values, and have everything work EXCEPT the
image pushing scripts.

Spin up gke cluster and reconfigure laptop to use it sanely:

    $ gke-up.sh
    
Push consul-dev image to gcr.io (edit this script to use the proper gcr.io links):

    $ cp hack/push-consul-dev-image.sh $CONSUL_PATH
    $ cd $CONSUL_PATH
    $ ./push-consul-dev-image.sh

Push consul-k8s-dev image to gcr.io (edit this script to use the proper gcr.io links):

    $ cp hack/push-consul-k8s-dev-image.sh $CONSUL_K8S_PATH
    $ cd $CONSUL_K8S_PATH
    $ ./push-consul-k8s-dev-image.sh
    
Bring up helm, tiller, gossip keys, license keys, consul helm, and pingpong:

    $ ./helm-up.sh
    
Nuke helm and associated stuff so you can reinstall:

    $ ./helm-del.sh
