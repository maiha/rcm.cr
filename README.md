# rcm.cr [![Build Status](https://travis-ci.org/maiha/rcm.cr.svg?branch=master)](https://travis-ci.org/maiha/rcm.cr)

Redis Cluster Manager in Crystal

- in beta stage (crystal-0.18.2)

## Usage (information features)

### nodes

- provides human-friendly output rather than `redis-cli`

```shell
% rcm -p 7001 nodes
89580c [127.0.0.1:7001](0)  master(*)   0-5000
47778f [127.0.0.1:7004](0)    +slave(*)   (slave of 127.0.0.1:7001)
72e796 [127.0.0.1:7002](0)  master(*)   5001-10000
fe9c7d [127.0.0.1:7005](0)    +slave(*)   (slave of 127.0.0.1:7002)
1f340e [127.0.0.1:7003](0)  master(*)   10001-16383
021b80 [127.0.0.1:7006](0)    +slave(*)   (slave of 127.0.0.1:7003)
5982db [127.0.0.1:7007](0)  standalone(*)
[OK] All 16384 slots are covered by 3 masters and 3 slaves.
[OK] All slots are available with 2 replication factor(s)
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

## Usage (utility features)

#### import

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
- [ ] Info
  - [ ] Suggest rebalancing nodes
- [ ] Check
  - [x] Nodes health check
  - [x] Slots coverage check
- [ ] Utils
  - [ ] Rebalance nodes
  - [ ] Bulkinsert on import
  - [ ] Bulkinsert on import
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
