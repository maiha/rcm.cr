# rcm.cr [![Build Status](https://travis-ci.org/maiha/rcm.cr.svg?branch=master)](https://travis-ci.org/maiha/rcm.cr)

Redis Cluster Manager in Crystal

- (still in beta stage)

## Usage

#### nodes

```shell
% rcm -p 7001 nodes
2afb4d [127.0.0.1:7001]   master(*)   0-5460
56f195 [127.0.0.1:7004]     +slave(*)   (connected 127.0.0.1:7001)
7fc615 [127.0.0.1:7007]     +slave(*)   (connected 127.0.0.1:7001)
7f193d [127.0.0.1:7002]   master(*)   5461-10922
51fba7 [127.0.0.1:7005]     +slave(*)   (connected 127.0.0.1:7002)
053dd7 [127.0.0.1:7003]   master(*)   10923-16383
1c8f39 [127.0.0.1:7006]     +slave(*)   (connected 127.0.0.1:7003)
b80784 [127.0.0.1:7008]   master(*)
6644fc [127.0.0.1:7009]   master(*)
```

#### meet

```shell
% rcm -p 7002 meet 127.0.0.1 7001
```

#### replicate

```shell
% rcm -p 7004 replicate 2afb4d
```

## Installation

```shell
% make
% cp bin/rcm ~/bin/
```

## TODO

- [ ] Dryrun
- [ ] Check
  - [ ] Nodes health check
  - [ ] Slots coverage check
- [ ] Debug
  - [ ] Slots filler

## Contributing

1. Fork it ( https://github.com/maiha/rcm.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [maiha](https://github.com/maiha) maiha - creator, maintainer
