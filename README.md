# rcm.cr [![Build Status](https://travis-ci.org/maiha/rcm.cr.svg?branch=master)](https://travis-ci.org/maiha/rcm.cr)

Redis Cluster Manager

## Features
- manage: creates cluster easily and provides many commands
- monitor: watches nodes periodically on cli
- httpd: provides http api service to redis

## Why not use redis-trib.rb?

- That has ugly syntax. (why SHA1?)
- That doesn't support AUTH and manual F/O and ....
- That depends `ruby` and `redis-cli`.

|                  | redis-trib                                                                   | rcm                                         |
|------------------|------------------------------------------------------------------------------|---------------------------------------------|
| Replicate        | redis-cli -p 7004 cluster replicate 34f256608ae6b6881cf1ba551e980308ef06756a | rcm -p 7004 replicate :7001                 |
| Manual F/O       | N/A                                                                          | rcm -p 7004 failover rcm -p 7001 failback   |
| Create with AUTH | N/A                                                                          | rcm -a XXX create ...                       |
| Migrate          | (slow : send N-times commands for N keys)                                    | (bulk : send like 10000 keys in 1 command ) |
| Portability      | docker run ruby:2.3 ruby redis-trib ...                                      | docker run alpine rcm ...                   |

If you don't mind these points at all, I recommend you to use `redis-trib`.

## Installation

#### Static Binary is ready for x86_64 linux

- https://github.com/maiha/rcm.cr/releases

#### Compile from source

- tested on crystal-0.20.4

```shell
% shards update  # first time only
% make
% cp bin/rcm /usr/local/bin/
```

## Usage (information features)

### schema

- show cluster schema about node dependencies

```shell
% rcm -p 7000 schema
[0-3276     ] 192.168.0.1:7001 192.168.0.2:7002 192.168.0.3:7003
[3277-6553  ] 192.168.0.2:7001 192.168.0.3:7002 192.168.0.4:7003
[6554-9830  ] 192.168.0.3:7001 192.168.0.4:7002 192.168.0.5:7003
[9831-13107 ] 192.168.0.4:7001 192.168.0.1:7003 192.168.0.5:7002
[13108-16383] 192.168.0.5:7001 192.168.0.1:7002 192.168.0.2:7003
```

- It can be used as continuous test for node dependencies.
- For example, we can easily alert failover or node down by crontab.

```shell
% rcm -p 7000 schema > /data/redis-cluster-7000.schema
```

```crontab
*/5 * * * * diff /data/redis-cluster-7000.schema $(rcm -p 7000 schema)
```

### status

- summarize nodes status in the cluster

```shell
% rcm -p 7000 status
[0-3000     ] master(127.0.0.1:7012) with 2 slaves
[3001-6000  ] master(127.0.0.1:7001) with 1 slaves
[6001-9000  ] master(127.0.0.1:7002) with 1 slaves
[9001-12000 ] master(127.0.0.1:7003) with 1 slaves
[12001-16383] master(127.0.0.1:7004) with 1 slaves

% rcm -p 7000 status -v
[0-3000     ] M(127.0.0.1:7012) S(127.0.0.1:7000) S(127.0.0.1:7014)
[3001-6000  ] M(127.0.0.1:7001) S(127.0.0.1:7006) S(127.0.0.1:7008) S(127.0.0.1:7011)
[6001-9000  ] M(127.0.0.1:7002) S(127.0.0.1:7007)
[9001-12000 ] M(127.0.0.1:7003) S(127.0.0.1:7013)
[12001-16383] M(127.0.0.1:7004) S(127.0.0.1:7009)
```

### nodes

- provides human-friendly output rather than `redis-cli`

```shell
% rcm -p 7001 nodes
b98ca1 [127.0.0.1:7001](0)  [0-5000     ] master(*)
835bea [127.0.0.1:7004](0)    +slave(*) of 127.0.0.1:7001
8a3c07 [127.0.0.1:7002](0)  [5001-10000 ] master(*)
0d0c75 [127.0.0.1:7005](0)    +slave(*) of 127.0.0.1:7002
33d324 [127.0.0.1:7003](0)  [10001-16383] master(*)
4a4da6 [127.0.0.1:7006](0)    +slave(*) of 127.0.0.1:7003
2581a1 [127.0.0.1:7007](0)  standalone master(*)
[OK] All 16384 slots are covered by 3 masters and 3 slaves.
[OK] All slots are available with 2 replication factor(s).
```
- NOTICE: This sends `INFO keyspace` to all nodes.

### info

- summarize INFO for each nodes

```shell
% rcm -p 7001 info
edb22e [127.0.0.1:7001]  ver(3.2.0), cnt(7633), mem(2.27M;noev;0%), days(0)
f0da61 [127.0.0.1:7002]  ver(3.2.0), cnt(8751), mem(2.61M;noev;0%), days(0)
```

- arg can be used to select a specific line like `grep` arg INFO

```shell
% rcm -p 7001 info role,cnt,day
edb22e [127.0.0.1:7001]  role(master), cnt(7633), days(0)
f0da61 [127.0.0.1:7002]  role(master), cnt(8751), days(0)
```

- reserved field names for easy access
  - `v` , `ver` , `version` : delegate to `redis_version`
  - `m` , `mem` , `memory` : summarize `used_memory_human` , `maxmemory_policy` and `maxmemory_human`
  - `cnt`, `count` : extract `db0:keys=(\d+)`
  - `d`, `day` : delegate to `uptime_in_days`

- NOTICE: This sends `INFO` to all nodes.

### slot : calculate keyslot values

```shell
% rcm slot foo
12182

% rcm slot foo bar -v
foo     12182
bar     5061

% rcm slot foo "{foo}.bar" -v
foo     12182
{foo}.bar       12182
```

## Usage (cluster feature)

- create : ADDSLOTS, MEET, REPLICATE
- join   : just MEET and wait all nodes to join the cluster
- forget : remove the node from cluster

### create : create cluster automatically

```shell
% rcm create 192.168.0.1:7001 192.168.0.2:7002 -n  # dryrun
% rcm create 192.168.0.1:7001 192.168.0.2:7002
% rcm create --masters 5 192.168.0.1:7001 192.168.0.2:7002 ...
```
- master size can be set by "--masters NUM"
- otherwise hosts count is used in default

### join : create cluster autmatically without addslots and replicate

```shell
% rcm join 192.168.0.1:7001 192.168.0.2:7002 ...
```

### create cluster manually

```shell
% rcm -p 7001 addslots -5000       # means 0-5000
% rcm -p 7002 addslots 5001-10000
% rcm -p 7003 addslots 10001-      # means 10001..16383

% rcm -p 7002 meet 127.0.0.1:7001
% rcm -p 7003 meet 127.0.0.1:7001
```

### forget : send "CLUSTER FORGET" to all nodes except the given node

For example, assume that a node (port :7004) is broken where `rcm nodes` prints like this.

```
a830a2 [192.168.0.1:7003](177877)    +slave(*) of 192.168.0.1:7002
3008b0 [127.0.0.1:0]   (    -1)  standalone master,fail,noaddr(!)
```

Here, we want to remove the node that was running on port:7004 (sha1: 3008b0...).

```shell
% rcm -p 7003 forget 3008b0
```

## Usage (replication features)

### start replication

- `meet` and `replicate` (ex. make :7004 slaveof :7001)

```shell
% rcm -p 7004 meet 127.0.0.1:7001       # same as "meet :7001" for localhost
% rcm -p 7004 replicate 127.0.0.1:7001  # same as "replicate :7001" for localhost
```

### switch master and slave

#### native redis cluster protocol

- `failover` (slave feature) : becomes master with agreement
- `takeover` (slave feature) : becomes master without agreement

#### rcm methods for graceful failover

- `wait` : wait for replication to finish
- `fail` (master feature) : becomes slave and wait a new master is up (linked)
- `failback` (slave feature) : becomes master and wait data sync is finished

```shell
% rcm -p 7001 fail      # 7001: master -> slave (now we can stop 7001 gracefully)
% rcm -p 7001 failover  # 7001: slave -> master (now we can stop slaves gracefully)
```

- Sequentially applying `fail` and `failover` means NOP

### advise

- In biased replications, `nodes` and `advise` advise a command to fix it.
```
% rcm -p 7001 nodes
...
[OK] All slots are available with 2+ replication factor(s).
advise: This can provide better replication. (rf of '127.0.0.1:7017': 2 -> 3)
  rcm -h '127.0.0.1' -p 7011 REPLICATE 127.0.0.1:7017

% rcm -h '127.0.0.1' -p 7011 REPLICATE 127.0.0.1:7017
REPLICATE 127.0.0.1:7017
OK

% rcm -p 7001 nodes
...
[OK] All slots are available with 3 replication factor(s).
```

- `advise --yes` is suit for batch.

```
# NOP when replication is well balanced
% rcm -p 7001 advise --yes

# `replicate` command is executed automatically when unblanaced
% rcm -p 7001 advise --yes
2016-06-23 21:21:49 +0900: BetterReplication: rf of '127.0.0.1:7016': 2 -> 3
rcm -h '127.0.0.1' -p 7012 REPLICATE 127.0.0.1:7016
REPLICATE 127.0.0.1:7016
OK
```

## Usage (utility features)

### watch (experimental)

- provides continual monitoring using curses
- ex) `rcm -p 7001 watch`

```
2016-06-27 09:54:36 +0900

[0-5000     ] 127.0.0.1:7001(5001) .........++..................
    +slave    127.0.0.1:7004(5001) .........++..................
[5001-10000 ] 127.0.0.1:7005(5000) ..........++.................
    +slave    127.0.0.1:7002(5000) ..........++.....EEEEEEE.....
[10001-16383] 127.0.0.1:7003(6384) ...........++................
    +slave    127.0.0.1:7006(6384) .......EEEEEEE.+.............
 ( no slots ) 127.0.0.1:7007(0)    .............................
```

### import

- (experimental) This is too slow deu to step import by one by
- works with using `SET`

```shell
% rcm -p 7001 import foo.tsv
```

### migrate

- migrate data from given redis server to this cluster
- options: `--count` for `SCAN`
- options: `--copy`, `--replace`
  - see: https://redis.io/commands/migrate

For example, we can migrate from `host1:6379` with `pass1` to new cluseter `cluster-broker1:7001` by following command.

```shell
% rcm -u pass1@host1:6379 migrate --to cluster-broker1:7001 --replace
```

## Usage (httpd : provides web interfaces)

- provides REST API that accepts "/CMD/args1/arg2/..." for redis

```shell
% rcm -p 7001 httpd :3000
% curl 127.0.0.1:3000/SET/hello/world  # same as "SET hello world"
OK
% curl 127.0.0.1:3000/GET/hello        # same as "GET hello"
world

# When redis requires AUTH(xxx), httpd automatically provides basic auth with "redis:xxx".
% rcm -u xxx@:7001 httpd :3000
% curl -u redis:xxx 127.0.0.1:3000/INCR/cnt
1

# The username of basic auth can be overwriten by listen arg like 'admin@'.
% rcm -u xxx@:7001 httpd admin@127.0.0.1:3000
% curl -u admin:xxx 127.0.0.1:3000/INCR/cnt
2
```

- output format is one of "txt", "raw", "resp", "json"

```shell
% curl 127.0.0.1:3000/GET/hello.txt  # => "world\n"
% curl 127.0.0.1:3000/GET/hello.raw  # => world
% curl 127.0.0.1:3000/GET/hello.resp # => $5\r\nworld\r\n
% curl 127.0.0.1:3000/GET/hello.json # => {"get":"world"}
```

## Usage (redis commands)

- All other args will be passed to redis as is.
- In this case, standard or clustered redis is automatically guessed.

```shell
(standard redis is running on 6379)
% rcm config get maxmemory
["maxmemory", "10000000"]

(clustered redis is running on 7001,7002,... with AUTH `dev`)
% rcm -u dev@:7002 config get maxmemory
["maxmemory", "10000000"]
```

## Connecting to nodes

various ways to connect to nodes

- `-h <host>`
- `-p <port>`
- `-a <password>`
- `-u <uri>`

```shell
% rcm ...                 # "127.0.0.1:6379" (default)
% rcm -h 192.168.0.1 ...  # "192.168.0.1:6379"
% rcm -p 7001 ...         # "127.0.0.1:7001"
% rcm -p 7001 -a xyz ...  # "127.0.0.1:7001" with AUTH "xyz"
% rcm -u redis://foo ...  # "foo:6379" (strict uri form)
% rcm -u foo ...          # "foo:6379" (scheme is optional)
% rcm -u :7001 ...        # "127.0.0.1:7001"
% rcm -u foo:7001 ...     # "foo:7001"
% rcm -u xyz@foo:7001 ... # "foo:7001" with AUTH "xyz"
% rcm -u xyz@foo:7001 ... # "foo:7001" with AUTH "xyz"
% rcm -u xyz@ ...         # "127.0.0.1:6379" with AUTH "xyz"
% rcm -u xyz@:7001 ...    # "127.0.0.1:7001" with AUTH "xyz"
% rcm -u xyz@foo ...      # "foo:6379" with AUTH "xyz"
```

## Usage (as a crystal library)

see `examples/*.cr`

But, you'd better use `redis-cluster.rb` rather than this for library.

## TODO

- [ ] Dryrun
- [ ] Check
  - [x] Nodes health check
  - [x] Slots coverage check
  - [x] detect orphaned master
  - [x] detect orphaned slave
- [ ] Schema
  - [x] Dump cluster schema
  - [ ] Reset node dependencies by schema file
- [ ] Advise
  - [x] Rebalance nodes
  - [ ] Rebalance slots
- [ ] Utils
  - [x] Create cluster
  - [x] Rebalance nodes
  - [ ] Rebalance slots
  - [ ] Bulkinsert on import
  - [x] Watch monitoring
  - [x] Graceful failover
- [x] Web UI
  - [x] Command Api
  - [x] Cluster Info
- [ ] Debug
  - [ ] Scan slots

## Contributing

1. Fork it ( https://github.com/maiha/rcm.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [maiha](https://github.com/maiha) maiha - creator, maintainer
