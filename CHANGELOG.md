# CHANGELOG for mixed_gauge
## 1.1.0
- Replication support. #5

## 1.0.0
- Change cluster slots definition interface: does not specify entire slots,
    but specify only slots size.
- Add config validation.
- Change class name of generated model: SubModel -> Shard

## 0.2.1
- Fix performance issue that `MixedGauge::Model.shard_for` is very slow.

## 0.2.0
- Replace default hash function from MD5 to CRC32. CRC32 is more distributed
  for random data and more speedy than MD5.

## 0.1.4
- Support executing queries in parallel.

## 0.1.3
- Rake tasks to setup database cluster.

## 0.1.2
- Enable to register before hook on `.put!`.
- Enable to define arbitrary methods to model class.
- Arbitrary hash function registeration.
- `.get!` to raise error when record not found.

## 0.1.1
- Fix NoMethodError bug on MixedGauge::Model.
- Improve tests, measure coverage.
