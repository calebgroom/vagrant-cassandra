# vagrant-cassandra

vagrant-cassandra quickly provisions a multi-VM [Cassandra](http://cassandra.apache.org/) deployment using [Vagrant](http://vagrantup.com). It leverages the [cassandra-chef-cookbook](https://github.com/michaelklishin/cassandra-chef-cookbook) project to do the heavy lifting.

## Dependencies

* Vagrant
* VirtualBox
* librarian

## Usage

Deploying a three-node Cassandra cluster:

    git clone git://github.com/calebgroom/vagrant-cassandra.git
    cd vagrant-cassandra/vagrant
    librarian-chef install
    cd ..
    vagrant up
    
SSH into the first node and check the status of the ring:

    vagrant ssh node1
    /usr/local/cassandra/bin/nodetool -h 192.168.2.10 ring
    Address         DC          Rack        Status State   Load            Effective-Ownership Token
    113427455640312821154458202477256070484     
    192.168.2.10    datacenter1 rack1       Up     Normal  83.19 KB        66.67%              0                                           
    192.168.2.11    datacenter1 rack1       Up     Normal  65.91 KB        66.67%              56713727820156410577229101238628035242      
    192.168.2.12    datacenter1 rack1       Up     Normal  52.62 KB        66.67%              113427455640312821154458202477256070484
    
## Loading Sample Data

SSH into one of the nodes and open a command-line prompt to enter Cassandra commands:

    vagrant ssh node2
    /usr/local/cassandra/bin/cassandra-cli -h 192.168.2.11
    
Copy and paste this sample data set:

    create keyspace demo
      with placement_strategy = 'SimpleStrategy'
      and strategy_options = {replication_factor: 2};

    use demo;

    create column family Users                
      with key_validation_class = 'UTF8Type'    
      and comparator = 'UTF8Type'               
      and default_validation_class = 'UTF8Type';

    update column family Users with
      column_metadata =
        [
          {column_name: first, validation_class: UTF8Type},
          {column_name: last, validation_class: UTF8Type},
          {column_name: age, validation_class: UTF8Type, index_type: KEYS}
        ];

    assume Users keys as utf8;

    set Users['jsmith']['first'] = 'John';
    set Users['jsmith']['last'] = 'Smith';
    set Users['jsmith']['age'] = '38';

Verify another node in the cluster can read the `jsmith` record:

    vagrant ssh node3
    /usr/local/cassandra/bin/cassandra-cli -h 192.168.2.12
    [default@unknown] use demo;
    Authenticated to keyspace: demo
    [default@demo] get Users['jsmith'];
    => (column=age, value=38, timestamp=1355649566834000)
    => (column=first, value=John, timestamp=1355649564055000)
    => (column=last, value=Smith, timestamp=1355649564391000)
    Returned 3 results.
    Elapsed time: 51 msec(s).

## Fail a Node

The `demo` keyspace has a replication factor of 2. Stop Cassandra on one of the nodes and verify that the `jsmith` record is still retrievable.

Take down node1:

    vagrant ssh node1
    sudo /etc/init.d/cassandra stop
    
Verify that node3 can still read:

    [default@unknown] use demo;
    Authenticated to keyspace: demo
    [default@demo] get Users['jsmith'];
    => (column=age, value=38, timestamp=1355649566834000)
    => (column=first, value=John, timestamp=1355649564055000)
    => (column=last, value=Smith, timestamp=1355649564391000)
    Returned 3 results.
    Elapsed time: 92 msec(s).

Taking down node1 and node2 *might* prevent node3 from being able to read the `jsmith` record if node3 is not responsible for the area in the keyspace where the record is stored.