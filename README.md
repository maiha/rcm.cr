# rcm.cr [![Build Status](https://travis-ci.org/maiha/rcm.cr.svg?branch=master)](https://travis-ci.org/maiha/rcm.cr)

Redis Cluster Manager in Crystal

- binary download: https://github.com/maiha/rcm.cr/releases

## Usage (information features)

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

## Usage (replication features)

### become slave

- `meet` and `replicate` (ex. make :7004 slaveof :7001)

```shell
% rcm -p 7004 meet 127.0.0.1:7001       # same as "meet :7001" for localhost
% rcm -p 7004 replicate 127.0.0.1:7001  # same as "replicate :7001" for localhost
```

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

### ping (experimental)

- provides continual monitoring using curses
- ex) `rcm -p 7001 ping`

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

```shell
% rcm -p 7001 import foo.tsv
```

## Installation

```shell
% make
% cp bin/rcm ~/bin/
```

## TODO

- [ ] Dryrun
- [ ] Check
  - [x] Nodes health check
  - [x] Slots coverage check
  - [x] detect orphaned master
  - [x] detect orphaned slave
- [ ] Advise
  - [x] Rebalance nodes
  - [ ] Rebalance slots
- [ ] Utils
  - [ ] Create cluster
  - [x] Rebalance nodes
  - [ ] Rebalance slots
  - [ ] Bulkinsert on import
  - [x] Ping monitoring
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
