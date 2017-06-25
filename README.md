# Demo MongoDB Deployment to GKE with Kubernetes

An example project demonstrating the deployment of a MongoDB Replica Set via Kubernetes on the Google Container Platform (GKE). Contains example Kubernetes YAML resource files (in the 'resource' folder) and associated Kubernetes based Bash scripts (in the 'scripts' folder) to configure the environment and deploy a MongoDB Replica Set.

For further background information on what these scripts and resource files do, see the series of related blog posts written by this project's author:

* [Deploying a MongoDB Replica Set as a GKE Kubernetes StatefulSet](http://todo)
* Configuring Some Key Production Settings for MongoDB on GKE Kubernetes (coming soon)
* Using the Enterprise Version of MongoDB on GKE Kubernetes (coming soon)

## 1  How To Run

### 1.1 Prerequisites

Ensure the following dependencies are already fulfilled on your host Linux/Windows/Mac Workstation/Laptop:

1. An account has been registered with the Google Compute Platform (GCP). You can sign up to a [free trial](https://cloud.google.com/free/) for GCP. Note: The free trial places some restrictions on account resource quotas, in particular restricting storage to a maximum of 100GB.
2. GCP’s client command line tool [gcloud](https://cloud.google.com/sdk/docs/quickstarts) has been installed. 
3. Your local workstation has been initialsied to: (1) use your GCP account, (2) install the Kubernetes command tool (“kubectl”), (3) configure authentication credentials, and (4) set the default GCP zone to be deployed to:

    ```
    $ gcloud init
    $ gcloud components install kubectl
    $ gcloud auth application-default login
    $ gcloud config set compute/zone europe-west1-b
    ```

**Note:** If you want to specify an alternative zone to deploy to, in the above command, you can first view the list of available zones by running the command: `$ gcloud compute zones list`

### 1.2 Main Deployment Steps 

1. To create a Kubernetes cluster, create the required disk storage (and associated PersistentVolumes), and deploy the MongoDB Service (including the StatefulSet running "mongod" containers), via a command-line terminal/shell, execute the following:

    ```
    $ cd scripts
    $ ./generate.sh
    ```

2. Re-run the following command, until all 3 “mongod” pods (and their containers) have been successfully started (i.e. once they show "Status" is "Running”; usually takes a minute or two).

    ```
    $ kubectl get all
    ```

To view the the state of the deployed environment you can also use the [Google Cloud Platform Console](https://console.cloud.google.com) (look at both the “Container Engine” and the “Compute Engine” sections of the Console).

3. Execute the following script which connects to the first Mongod instance running in a container of the Kubernetes StatefulSet, via the Mongo Shell, to (1) initalise the MongoDB Replica Set, and (2) create a MongoDB admin user (specify the password you want as the argument to the script, replacing 'abc123').

    ```
    $ ./configure_repset_auth.sh abc123
    ```

You should now have a MongoDB Replica Set initialised, secured and running in a Kubernetes Stateful Set.

### 1.3 Example Tests To Run To Check Things Are Working

Use this section to prove:

1. Data is being replicated between members of the containerised replica set.
2. Data is retained even when the MongoDB Service/StatefulSet is removed and then re-created (by virtue of re-using the same Persistent Volume Claims).

Connect to the container running the first "mongod" replica, then use the Mongo Shell to authenticate and add some test data to a database:

    $ kubectl exec -it mongod-0 -c mongod-container bash
    $ mongo
    > db.getSiblingDB('admin').auth("main_admin", "abc123");
    > use test;
    > db.testcoll.insert({a:1});
    > db.testcoll.insert({b:2});
    > db.testcoll.find();
    
Exit out of the shell and exit out of the first container (“mongod-0”). Then connect to the second container (“mongod-1”), run the Mongo Shell again and see if the previously inserted data is visible to the second "mongod" replica:

    ```
    $ kubectl exec -it mongod-1 -c mongod-container bash
    $ mongo
    > db.getSiblingDB('admin').auth("main_admin", "abc123");
    > db.setSlaveOk(1);
    > use test;
    > db.testcoll.find();
    ```

You should see that the two records inserted via the first replica, are visible to the second replica.

To see if Persistent Volume Claims really are working, run a script to drop the Service & StatefulSet (thus stopping the pods and their “mongod” containers) and then a script to re-create them again:

    ```
    $ ./delete_service.sh
    $ ./recreate_service
    $ kubectl get all
    ```

As before, keep re-running the last command above, until you can see that all 3 “mongod” pods and their containers have been successfully started again. Then connect to the first container, run the Mongo Shell and query to see if the data we’d inserted into the old containerised replica-set is still present in the re-instantiated replica set:

    ```
    $ kubectl exec -it mongod-0 -c mongod-container bash
    $ mongo
    > use test;
    > db.testcoll.find();
    ```

You should see that the two records inserted earlier, are still present.

### 1.4 Undeploying & Cleaning Down the Kubernetes Environment

**Important:** This step is required to ensure you aren't continously charged by Google Cloud for an environment you no longer need.

Run the following script to undeploy the MongoDB Service & StatefulSet plus related Kubernetes resoruces, followed by the removal of the GCE disks before finally deleting the GKE Kubernetes cluster.

    ```
    $ ./teardown.sh
    ```

It is also worth checking in the [Google Cloud Platform Console](https://console.cloud.google.com), to ensure all resources have been removed correctly.

