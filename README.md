# mixed_gauge
[![Build Status](https://travis-ci.org/cookpad/mixed_gauge.svg?branch=master)](https://travis-ci.org/cookpad/mixed_gauge) [![Coverage Status](https://coveralls.io/repos/taiki45/mixed_gauge/badge.svg?branch=master)](https://coveralls.io/r/taiki45/mixed_gauge?branch=master) [![Code Climate](https://codeclimate.com/github/taiki45/mixed_gauge/badges/gpa.svg)](https://codeclimate.com/github/taiki45/mixed_gauge) [![Gem Version](https://badge.fury.io/rb/mixed_gauge.svg)](http://badge.fury.io/rb/mixed_gauge)

A simple and robust ActiveRecord extension for database sharding.
mixed_gauge offers shards management with hash slots and re-sharding support.
It enable you to execute efficient queries to single node with KVS-like interface.
And you can even execute limited RDB queries to all nodes with ActiveRecord interface in-parallel.

mixed_gauge is already used in production. [(blog post in Japanese)](http://techlife.cookpad.com/entry/2015/06/22/134108)

## Goal and concept
- Simple
- No downtime migrations
- Rollback-able operations

Database sharding tend to be over-complexed. There are cases which need these complex database sharding but in some cases database sharding can be more simple. The large data set which is enoght big to partition should be designed to be distributed, or should be re-design if it wasn't. Design to be distributed uses key based relation or reverse indexes to fits its limitation. In that case, the data set is almost design to be distributed, mixed_gauge strongly encourages your database sharding by its simplicity.

We, offer 24/7 services, must keep our services running. mixed_gauge supports online migrations: adding new nodes to cluster or removing some existing nodes from cluster. It comes with "key distibution model with hash slots" and  database replication and multi-master replication. In sharding we need re-sharding, move data from node to another node in cluster, when adding or removing new nodes from cluster. But by setting some rule to node management and using replication, we can finish moving data before adding or removing nodes. The detail operations are specified later chapter of this document.

All operaions should be rollback-able in case of any failures. mixed_gauge's node management can rollback adding and removing nodes operation. The detail operations are specified later chapter of this document.


## Main components of sharding teqnique
### Distribution model
mixed_gauge's database sharding is based on keys distribution model with hash slots. The key space is split into arbitrary size of slots. `hash(v) mod N` determines which slot is used where `N` is size of configured hash slots. Hash slot is a virtual node and it is assigned to real node.

The default hash function is CRC32 which has better perfomance for this kind of cases. You can use other hash function.

### Node management
mixed_gauge's database sharding sets a rule to both adding nodes and removing nodes. The node size must be incresed by multiple of 2. At first, the node size is 1. Then the node size is incresed to 2, next is 4, and next of next is 8.

By setting this rule, we can move (copy) data from node to node before adding or removing nodes by "database replication". For example, when we have `cluster(A)`, which has single node A and node A is assigned (0..1023) hash slots, and plan to migrate to `cluster(A, B)`, which has 2 nodes A and B and node A is assigned (0..511) slots and node B is assigned (512..1023) slots, we can copy and replicate from A to B before migration then just balance hash slots to node B.

```
(1)              (2)                               (3)
   ┌───────┐           ┌───────┐       ┌───────┐         ┌───────┐       ┌───────┐
   │       │           │       │       │       │         │       │       │       │
   │   A   │           │   A   │──────▶│   B   │         │   A   │       │   B   │
   │       │           │       │       │       │         │       │       │       │
   └───────┘           └───────┘       └───────┘         └───────┘       └───────┘

    0..1023             0..1023                           0..511         512..1023
```

### Migration operations
```
(1) From 1 node cluster

     0..1023
    ┌───────┐
    │       │
    │       │
    │   A   │
    │       │
    │       │
    └───────┘

(2) Copy data and start replication

     0..1023
    ┌───────┐       ┌───────┐
    │       │       │       │
    │       │       │       │
    │   A   │──────▶│   B   │
    │       │       │       │
    │       │       │       │
    └───────┘       └───────┘

(3) Change auto_increment config
not to conflict id column

     0..1023
  1 ┌───────┐       ┌───────┐ 2
  3 │       │       │       │ 4
  5 │       │       │       │ 6
  . │   A   │──────▶│   B   │ .
  . │       │       │       │ .
    │       │       │       │
    └───────┘       └───────┘
   increment=2    increment=2
     offset=1       offset=2

(4) Start Multi-master replication

     0..1023
    ┌───────┐       ┌───────┐
    │       │──────▶│       │
    │       │       │       │
    │   A   │       │   B   │
    │       │       │       │
    │       │◀──────│       │
    └───────┘       └───────┘

(5) Deploy app and apply new cluster
configuration

    0..511         512..1023
   ┌───────┐       ┌───────┐
   │       │──────▶│       │
   │       │       │       │
   │   A   │       │   B   │
   │       │       │       │
   │       │◀──────│       │
   └───────┘       └───────┘

(6) Stop Multi-master replication

    0..511         512..1023
   ┌───────┐       ┌───────┐
   │       │       │       │
   │       │       │       │
   │   A   │       │   B   │
   │       │       │       │
   │       │       │       │
   └───────┘       └───────┘
```

In step 3, we set enough big offset not to conflict auto increment value
on applying config.


## Usage
Add additional database connection config to `database.yml`.

```yaml
# database.yml
production_user_001:
  adapter: mysql2
  username: user_writable
  host: db-user-001
production_user_002:
  adapter: mysql2
  username: user_writable
  host: db-user-002
production_user_003:
  adapter: mysql2
  username: user_writable
  host: db-user-003
production_user_004:
  adapter: mysql2
  username: user_writable
  host: db-user-004
```

Configure slots (virtual node for cluster) then assign slots to real node.

```ruby
MixedGauge.configure do |config|
  config.define_cluster(:user) do |cluster|
    # When slots per node * max nodes per cluster = (2 ** 10) * (2 ** 10)
    cluster.define_slot_size(1048576)
    cluster.register(0..262143, :production_user_001)
    cluster.register(262144..524287, :production_user_002)
    cluster.register(524288..786431, :production_user_003)
    cluster.register(786432..1048575, :production_user_004)
  end
end
```

Include `MixedGauge::Model` to your model class, specify cluster name for the
model, specify distkey which determines node to store.

```ruby
class User < ActiveRecord::Base
  include MixedGauge::Model
  use_cluster :user
  def_distkey :email
end
```

Use `.get` to retrive single record which is connected to proper
database node. Use `.put!` to create new record to proper database node.

`.all_shards` returns each model class which is connected to proper
database node. You can query with these models and aggregate result.

```ruby
User.put!(email: 'alice@example.com', name: 'alice')

alice = User.get('alice@example.com')
alice.age = 1
alice.save!

User.all_shards.flat_map {|m| m.find_by(name: 'alice') }.compact
```

When you want to execute queries in all nodes in parallel, use `.all_shards_in_parallel`.
It returns `Mixedgauge::AllShardsInParallel` and it offers some collection
actions which runs in parallel. It is aliased to `.parallel`.

```ruby
User.all_shards_in_parallel.map(&count) #=> 1
User.parallel.flat_map {|m| m.where(age: 1) }.size #=> 1
```

When you want find by non-distkey, not recomended though, you can define finder
methods to model class for convenience.

```ruby
class User < ActiveRecord::Base
  include MixedGauge::Model
  use_cluster :user
  def_distkey :email

  parent_methods do
    def find_from_all_by_name(name)
      all_shards_in_parallel.map {|m| m.find_by(name: name) }.compact.first
    end
  end
end

alice = User.find_from_all_by_name('Alice')
alice.age = 0
alice.save!
```

Sometimes you want to generates distkey value before validation. Since mixed_gauge
generates sub class of your models, AR's callback is usesless for this usecase,
so mixed_gauge offers its own callback method.

```ruby
class AccessToken < ActiveRecord::Base
  include MixedGauge::Model
  use_cluster :access_token
  def_distkey :token

  validates :token, presence: true

  def self.generate_token
    SecureRandom.uuid
  end

  before_put do |attributes|
    unless attributes[:token] || attributes['token']
      attributes[:token] = generate_token
    end
  end
end

access_token = AccessToken.put!
access_token.token #=> a generated token
```

## Sharding with Replication
mixed_gauge also supports replication.

In case you have 2 shards in cluster and each shard have read replica.

- db-user-101 --replicated--> db-user-102
- db-user-201 --replicated--> db-user-202

Your database connection configuration might be like this:

```yaml
# database.yml
production_user_001:
  adapter: mysql2
  username: user_writable
  host: db-user-101
production_user_002:
  adapter: mysql2
  username: user_writable
  host: db-user-201
production_user_readonly_001:
  adapter: mysql2
  username: user_readonly
  host: db-user-102
production_user_readonly_002:
  adapter: mysql2
  username: user_writable
  host: db-user-202
```

Your initializer for mixed_gauge might be like this:

```ruby
MixedGauge.configure do |config|
  config.define_cluster(:user) do |cluster|
    cluster.define_slot_size(1048576)
    cluster.register(0..524287, :production_user_001)
    cluster.register(524288..1048575, :production_user_002)
  end

  config.define_cluster(:user_readonly) do |cluster|
    cluster.define_slot_size(1048576)
    cluster.register(0..524287, :production_user_readonly_001)
    cluster.register(524288..1048575, :production_user_readonly_002)
  end
end
```

You can split read/write by defining AR model class for each connection:

```ruby
class User < ActiveRecord::Base
  include MixedGauge::Model
  use_cluster :user
  def_distkey :email
end

class UserReadonly < ActiveRecord::Base
  self.table_name = 'users'

  include MixedGauge::Model
  use_cluster :user_readonly
  def_distkey :email
end

User.put!(name: 'Alice', email: 'alice@example.com')
UserReadonly.get('alice@example.com')
```

If you want to switch specific shard to another shard in another cluster, define mapping between each model:

```ruby
class User < ActiveRecord::Base
  include MixedGauge::Model
  use_cluster :user
  def_distkey :email

  replicates_with slave: :UserReadonly
end

class UserReadonly < ActiveRecord::Base
  self.table_name = 'users'

  include MixedGauge::Model
  use_cluster :user_readonly
  def_distkey :email

  replicates_with master: :User
end
```

You can switch to another model which have connection to the shard by calling `.switch`:

```ruby
UserReadonly.all_shards do |readonly|
  target_ids = readonly.where(age: 0).pluck(:id)
  readonly.switch(:master) do |writable|
    writable.where(id: target_ids).delete_all
  end
end
```

## Advanced configuration
### Hash fucntion
Default hash fucntion is CRC32, which has better perfomance for this kind of
usecase.

But you can use arbitrary hash function like:

```ruby
# gem install fnv
require "fnv"
Mixedgauge.configure do |config|
  config.register_hash_function do |key|
    FNV.new.fnv1a_64(key)
  end
end
```

Suggested hash functions are:

- MurmurHash
- FNV Hash
- SuperFastHash


## Installation
Add this line to your application's Gemfile:

```ruby
gem 'mixed_gauge'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mixed_gauge


## Contributing
Feel free to pull request and issue :)
